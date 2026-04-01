data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "service" {
  name         = var.service_name
  machine_type = "e2-micro"
  zone         = "${var.region}-b"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
  }

  tags = ["svc-${var.service_name}-prod", "allow-ssh"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    cat > /opt/health_server.py << 'PY'
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path in ("/health", "/healthz", "/"):
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"ok\n")
                return
            self.send_response(404)
            self.end_headers()

        def log_message(self, format, *args):
            return

    if __name__ == "__main__":
        HTTPServer(("0.0.0.0", 9090), Handler).serve_forever()
    PY
    nohup python3 /opt/health_server.py &
  EOF

  labels = {
    service     = var.service_name
    environment = "production"
    team        = var.team
    managed-by  = "terraform"
  }
}

# Service ingress — allows application and health-check traffic from internal ranges.
# target_tags binds this rule to instances carrying the service_name tag.
resource "google_compute_firewall" "service_ingress" {
  name        = "${var.service_name}-ingress"
  network     = var.network
  project     = var.project_id
  description = "Allow ${var.service_name} traffic on service and health-check ports"

  allow {
    protocol = "tcp"
    ports    = [tostring(var.service_port), "9090"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = [var.service_name]
}

# Dedicated rule for Google Cloud health-check probes (source ranges are fixed
# Google-owned prefixes). Also targets by service_name tag.
resource "google_compute_firewall" "health_check" {
  name        = "${var.service_name}-health-check"
  network     = var.network
  project     = var.project_id
  description = "Allow Google Cloud health-check probes to ${var.service_name}"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = [var.service_name]
}

resource "google_compute_health_check" "service" {
  name    = "${var.service_name}-health"
  project = var.project_id

  tcp_health_check {
    port = 9090
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_monitoring_notification_channel" "oncall" {
  display_name = "${var.service_name} On-Call (${var.team})"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = var.alert_topic
  }
}

resource "google_monitoring_alert_policy" "health" {
  display_name = "${var.service_name} Health Check Failed"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "${var.service_name} Instance Not Running"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${google_compute_instance.service.instance_id}\" AND metric.type = \"compute.googleapis.com/instance/uptime\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.oncall.id]

  user_labels = {
    service = var.service_name
    team    = var.team
  }
}
