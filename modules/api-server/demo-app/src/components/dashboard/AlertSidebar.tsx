import { AlertTriangle, ExternalLink, Clock, Bot } from "lucide-react";
import { Link } from "react-router-dom";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export function AlertSidebar() {
  return (
    <div className="space-y-4">
      {/* Alert Card */}
      <div className="alert-card border-warning/40 fade-in">
        <div className="flex items-start gap-3">
          <div className="rounded-xl bg-gradient-to-br from-warning/20 to-warning/10 p-2.5 shadow-sm">
            <AlertTriangle className="h-5 w-5 text-warning" />
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="text-sm font-semibold text-foreground">Non-Compliant Resource Detected</h4>
            <p className="mt-1.5 text-sm text-muted-foreground leading-relaxed">
              <code className="text-xs bg-muted px-1.5 py-0.5 rounded-md font-mono">api-prod-server</code> is using{" "}
              <code className="text-xs bg-destructive/10 text-destructive px-1.5 py-0.5 rounded-md font-mono">c5.large</code>{" "}
              instead of approved t3 instance family.
            </p>
          </div>
        </div>
        
        <div className="mt-4 flex items-center gap-2 text-sm">
          <Bot className="h-4 w-4 text-muted-foreground" />
          <span className="text-muted-foreground">Auto-ticket</span>
          <Link 
            to="/tickets/INFRA-4721" 
            className="font-medium text-primary hover:underline"
          >
            INFRA-4721
          </Link>
          <span className="text-muted-foreground">created</span>
        </div>

        <div className="mt-3 rounded-lg bg-success/10 px-3 py-2.5 ring-1 ring-success/20">
          <p className="text-xs text-success font-medium flex items-center gap-1.5">
            <span className="h-1.5 w-1.5 rounded-full bg-success" />
            This is a Standard Change - no CAB approval required
          </p>
        </div>

        <div className="mt-4">
          <Link to="/tickets/INFRA-4721">
            <Button size="sm" className="w-full gap-2 button-primary">
              View Ticket Details
              <ExternalLink className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="card-elevated p-5 slide-in-right" style={{ animationDelay: "0.1s" }}>
        <h4 className="section-title mb-4">Recent Activity</h4>
        <div className="space-y-4">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 h-2.5 w-2.5 rounded-full bg-destructive ring-4 ring-destructive/10" />
            <div className="flex-1 min-w-0">
              <p className="text-sm text-foreground">Compliance violation detected</p>
              <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
                <Clock className="h-3 w-3" /> 2 hours ago
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <div className="mt-0.5 h-2.5 w-2.5 rounded-full bg-info ring-4 ring-info/10" />
            <div className="flex-1 min-w-0">
              <p className="text-sm text-foreground">Ticket INFRA-4721 auto-created</p>
              <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
                <Clock className="h-3 w-3" /> 2 hours ago
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <div className="mt-0.5 h-2.5 w-2.5 rounded-full bg-success ring-4 ring-success/10" />
            <div className="flex-1 min-w-0">
              <p className="text-sm text-foreground">Monthly compliance scan completed</p>
              <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
                <Clock className="h-3 w-3" /> 3 hours ago
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Slack Preview */}
      <div className="slack-preview slide-in-right" style={{ animationDelay: "0.2s" }}>
        <div className="px-4 py-3 bg-gradient-to-r from-[#4A154B] to-[#611f69] flex items-center gap-2">
          <svg className="h-4 w-4 text-white" viewBox="0 0 24 24" fill="currentColor">
            <path d="M5.042 15.165a2.528 2.528 0 0 1-2.52 2.523A2.528 2.528 0 0 1 0 15.165a2.527 2.527 0 0 1 2.522-2.52h2.52v2.52zm1.271 0a2.527 2.527 0 0 1 2.521-2.52 2.527 2.527 0 0 1 2.521 2.52v6.313A2.528 2.528 0 0 1 8.834 24a2.528 2.528 0 0 1-2.521-2.522v-6.313zM8.834 5.042a2.528 2.528 0 0 1-2.521-2.52A2.528 2.528 0 0 1 8.834 0a2.528 2.528 0 0 1 2.521 2.522v2.52H8.834zm0 1.271a2.528 2.528 0 0 1 2.521 2.521 2.528 2.528 0 0 1-2.521 2.521H2.522A2.528 2.528 0 0 1 0 8.834a2.528 2.528 0 0 1 2.522-2.521h6.312zm10.124 2.521a2.528 2.528 0 0 1 2.52-2.521A2.528 2.528 0 0 1 24 8.834a2.528 2.528 0 0 1-2.522 2.521h-2.52V8.834zm-1.271 0a2.528 2.528 0 0 1-2.521 2.521 2.528 2.528 0 0 1-2.521-2.521V2.522A2.528 2.528 0 0 1 15.166 0a2.528 2.528 0 0 1 2.521 2.522v6.312zm-2.521 10.124a2.528 2.528 0 0 1 2.521 2.52A2.528 2.528 0 0 1 15.166 24a2.528 2.528 0 0 1-2.521-2.522v-2.52h2.521zm0-1.271a2.528 2.528 0 0 1-2.521-2.521 2.528 2.528 0 0 1 2.521-2.521h6.312A2.528 2.528 0 0 1 24 15.166a2.528 2.528 0 0 1-2.522 2.521h-6.312z"/>
          </svg>
          <span className="text-white text-xs font-medium">#infra-alerts</span>
        </div>
        <div className="p-4 bg-card">
          <div className="flex items-start gap-3">
            <div className="h-9 w-9 rounded-lg bg-gradient-to-br from-primary to-[hsl(250,83%,60%)] flex items-center justify-center flex-shrink-0 shadow-md">
              <Bot className="h-4 w-4 text-white" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-foreground">Stratum Compliance</span>
                <Badge variant="info" className="text-[10px] px-1.5 py-0">APP</Badge>
                <span className="text-[10px] text-muted-foreground">Today at 2:34 PM</span>
              </div>
              <div className="mt-2 text-sm text-foreground space-y-1.5">
                <p className="font-medium text-destructive flex items-center gap-1.5">
                  <span className="h-2 w-2 rounded-full bg-destructive animate-pulse" />
                  Non-Compliant Instance Detected
                </p>
                <p><span className="font-medium text-muted-foreground">Instance:</span> api-prod-server</p>
                <p><span className="font-medium text-muted-foreground">Current:</span> c5.large</p>
                <p><span className="font-medium text-muted-foreground">Expected:</span> t3.* family</p>
              </div>
              <div className="mt-3 flex items-center gap-2">
                <span className="text-xs bg-muted hover:bg-muted/80 px-2 py-1 rounded-md cursor-pointer transition-colors">👀 2</span>
                <span className="text-xs bg-muted hover:bg-muted/80 px-2 py-1 rounded-md cursor-pointer transition-colors">👍 1</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
