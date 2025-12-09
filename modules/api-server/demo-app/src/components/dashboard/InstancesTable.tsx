import { Link } from "react-router-dom";
import { CheckCircle2, XCircle, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface Instance {
  id: string;
  name: string;
  instanceId: string;
  instanceType: string;
  standard: string;
  environment: string;
  status: "compliant" | "non-compliant";
  ticketId?: string;
}

const instances: Instance[] = [
  { id: "1", name: "web-frontend-prod", instanceId: "i-0f8e7d6c5b4a3210", instanceType: "t3.large", standard: "t3 family", environment: "Production", status: "compliant" },
  { id: "2", name: "auth-service-prod", instanceId: "i-1a2b3c4d5e6f7890", instanceType: "t3.medium", standard: "t3 family", environment: "Production", status: "compliant" },
  { id: "3", name: "api-prod-server", instanceId: "i-0a1b2c3d4e5f67890", instanceType: "c5.large", standard: "t3 family", environment: "Production", status: "non-compliant", ticketId: "INFRA-4721" },
  { id: "4", name: "db-replica-01", instanceId: "i-9f8e7d6c5b4a3210", instanceType: "t3.xlarge", standard: "t3 family", environment: "Production", status: "compliant" },
  { id: "5", name: "cache-cluster-prod", instanceId: "i-2b3c4d5e6f789012", instanceType: "t3.medium", standard: "t3 family", environment: "Production", status: "compliant" },
  { id: "6", name: "worker-service-prod", instanceId: "i-3c4d5e6f78901234", instanceType: "t3.large", standard: "t3 family", environment: "Production", status: "compliant" },
  { id: "7", name: "monitoring-stack", instanceId: "i-4d5e6f7890123456", instanceType: "t3.medium", standard: "t3 family", environment: "Production", status: "compliant" },
];

export function InstancesTable() {
  return (
    <div className="card-elevated overflow-hidden animate-slide-up" style={{ animationDelay: "0.1s" }}>
      <div className="px-6 py-5 border-b border-border">
        <h3 className="section-title text-base">Instance Compliance Status</h3>
        <p className="section-subtitle mt-1">Real-time monitoring of EC2 instance standards</p>
      </div>
      <div className="overflow-x-auto">
        <table className="table-modern">
          <thead>
            <tr>
              <th className="px-6 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">Instance Name</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">Instance Type</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">Standard</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">Environment</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">Status</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-muted-foreground uppercase tracking-wider">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-table-border">
            {instances.map((instance, index) => (
              <tr
                key={instance.id}
                className={cn(
                  "transition-all duration-200",
                  instance.status === "non-compliant" && "bg-destructive/5 hover:bg-destructive/8"
                )}
                style={{ animationDelay: `${0.05 * index}s` }}
              >
                <td className="px-6 py-4">
                  <div>
                    <p className={cn(
                      "text-sm font-medium",
                      instance.status === "non-compliant" ? "text-destructive" : "text-foreground"
                    )}>
                      {instance.name}
                    </p>
                    <p className="text-xs text-muted-foreground font-mono mt-0.5">{instance.instanceId}</p>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <code className={cn(
                    "text-sm px-2.5 py-1 rounded-lg font-mono",
                    instance.status === "non-compliant" 
                      ? "bg-destructive/10 text-destructive ring-1 ring-destructive/20" 
                      : "bg-muted text-foreground"
                  )}>
                    {instance.instanceType}
                  </code>
                </td>
                <td className="px-6 py-4 text-sm text-muted-foreground">{instance.standard}</td>
                <td className="px-6 py-4">
                  <Badge variant="neutral">{instance.environment}</Badge>
                </td>
                <td className="px-6 py-4">
                  {instance.status === "compliant" ? (
                    <div className="flex items-center gap-2 text-success">
                      <CheckCircle2 className="h-4 w-4" />
                      <span className="text-sm font-medium">Compliant</span>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2 text-destructive">
                      <XCircle className="h-4 w-4" />
                      <span className="text-sm font-medium">Non-Compliant</span>
                    </div>
                  )}
                </td>
                <td className="px-6 py-4">
                  {instance.status === "non-compliant" && instance.ticketId ? (
                    <Link to={`/tickets/${instance.ticketId}`}>
                      <Button size="sm" variant="outline" className="gap-2 hover:shadow-sm transition-shadow">
                        View Ticket
                        <ExternalLink className="h-3.5 w-3.5" />
                      </Button>
                    </Link>
                  ) : (
                    <span className="text-sm text-muted-foreground">—</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
