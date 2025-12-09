import { Clock, User, Tag, Folder, Link as LinkIcon, MessageSquare, Bot, History, ExternalLink, Server, FileCode, BookOpen, Github, Copy } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";

interface TicketDetailProps {
  ticketId: string;
}

export function TicketDetail({ ticketId }: TicketDetailProps) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Main Content */}
      <div className="lg:col-span-2 space-y-6">
        {/* Header */}
        <div className="rounded-lg border border-border bg-card p-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
                <span className="font-mono">{ticketId}</span>
                <span>•</span>
                <span>Infrastructure Change</span>
              </div>
              <h1 className="text-xl font-semibold text-foreground">
                Migrate non-compliant c5.large instance to t3 platform standard
              </h1>
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="info">Open</Badge>
              <Badge variant="neutral">Low Priority</Badge>
              <Badge variant="success">Standard Change</Badge>
            </div>
          </div>
        </div>

        {/* Description */}
        <div className="rounded-lg border border-border bg-card p-6">
          <h3 className="text-sm font-semibold text-foreground mb-4">Description</h3>
          <div className="prose prose-sm max-w-none text-foreground">
            <p className="text-muted-foreground mb-4">
              Automated ticket created by Platform Compliance monitoring.
            </p>
            
            <div className="bg-muted/50 rounded-lg p-4 font-mono text-xs space-y-1 mb-4">
              <p className="font-semibold text-foreground">Instance Details:</p>
              <p className="text-muted-foreground">• Instance ID: <span className="text-foreground">i-0a1b2c3d4e5f67890</span></p>
              <p className="text-muted-foreground">• Name: <span className="text-foreground">api-prod-server</span></p>
              <p className="text-muted-foreground">• Current Type: <span className="text-destructive">c5.large (non-compliant)</span></p>
              <p className="text-muted-foreground">• Target Type: <span className="text-success">t3.large (compliant)</span></p>
              <p className="text-muted-foreground">• Environment: <span className="text-foreground">Production</span></p>
              <p className="text-muted-foreground">• Region: <span className="text-foreground">eu-west-2</span></p>
            </div>

            <div className="mb-4">
              <p className="font-semibold text-foreground mb-2">Justification:</p>
              <p className="text-muted-foreground">
                Per platform standard <span className="font-medium text-primary">PS-2024-003</span>, all EC2 instances 
                should use t3 instance family to leverage pre-purchased Savings Plans. This instance was 
                flagged during monthly compliance audit.
              </p>
            </div>

            <div className="bg-success/10 rounded-lg p-4 border border-success/20">
              <p className="text-success font-medium text-sm">
                ✓ This is a Standard Change (SC-0042: Instance Family Migration) and does not require CAB approval. 
                Instance specifications (2 vCPU, 4GB RAM) remain unchanged.
              </p>
            </div>
          </div>
        </div>

        {/* Related Resources */}
        <div className="rounded-lg border border-border bg-card p-6">
          <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
            📎 Related Resources
          </h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between py-2 border-b border-border">
              <div className="flex items-center gap-3">
                <Server className="h-4 w-4 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground">Instance</p>
                  <p className="text-sm text-foreground font-mono">api-prod-server (i-0a1b2c3d4e5f67890)</p>
                </div>
              </div>
              <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                <Copy className="h-4 w-4" />
              </Button>
            </div>
            
            <div className="flex items-center justify-between py-2 border-b border-border">
              <div className="flex items-center gap-3">
                <FileCode className="h-4 w-4 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground">Config File</p>
                  <p className="text-sm text-foreground">main.tf <span className="text-muted-foreground">(line 389)</span></p>
                </div>
              </div>
              <a 
                href="https://github.dev/overmindtech/terraform-example/blob/main/main.tf#L389"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Button variant="outline" size="sm" className="gap-1.5">
                  Open in Editor
                  <ExternalLink className="h-3.5 w-3.5" />
                </Button>
              </a>
            </div>
            
            <div className="flex items-center justify-between py-2 border-b border-border">
              <div className="flex items-center gap-3">
                <BookOpen className="h-4 w-4 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground">Runbook</p>
                  <p className="text-sm text-foreground">Instance Migration Guide</p>
                </div>
              </div>
              <a href="#" className="text-sm text-primary hover:underline">View →</a>
            </div>
            
            <div className="flex items-center justify-between py-2">
              <div className="flex items-center gap-3">
                <Github className="h-4 w-4 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground">Repository</p>
                  <p className="text-sm text-foreground">overmindtech/terraform-example</p>
                </div>
              </div>
              <a 
                href="https://github.com/overmindtech/terraform-example"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-primary hover:underline flex items-center gap-1"
              >
                View on GitHub
                <ExternalLink className="h-3 w-3" />
              </a>
            </div>
          </div>
        </div>

        {/* Activity */}
        <div className="rounded-lg border border-border bg-card p-6">
          <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
            <MessageSquare className="h-4 w-4" />
            Activity
          </h3>
          <div className="space-y-4">
            <div className="flex gap-3">
              <div className="h-8 w-8 rounded-full bg-gradient-to-br from-primary to-info flex items-center justify-center flex-shrink-0">
                <Bot className="h-4 w-4 text-white" />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-sm font-medium text-foreground">Platform Compliance Bot</span>
                  <span className="text-xs text-muted-foreground">2 hours ago</span>
                </div>
                <p className="text-sm text-muted-foreground">
                  Ticket auto-created from compliance alert. Instance api-prod-server flagged for non-standard instance type.
                </p>
              </div>
            </div>
            
            <Separator />
            
            <div className="flex gap-3">
              <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center flex-shrink-0">
                <History className="h-4 w-4 text-muted-foreground" />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-sm font-medium text-foreground">System</span>
                  <span className="text-xs text-muted-foreground">2 hours ago</span>
                </div>
                <p className="text-sm text-muted-foreground">
                  Linked to standard change template <span className="font-mono text-primary">SC-0042</span>. No CAB approval required.
                </p>
              </div>
            </div>
          </div>

          {/* Add Comment */}
          <div className="mt-6 pt-4 border-t border-border">
            <textarea
              placeholder="Add a comment..."
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring resize-none"
              rows={3}
            />
            <div className="mt-2 flex justify-end">
              <Button size="sm">Add Comment</Button>
            </div>
          </div>
        </div>
      </div>

      {/* Sidebar */}
      <div className="space-y-6">
        {/* Details */}
        <div className="rounded-lg border border-border bg-card p-5">
          <h3 className="text-sm font-semibold text-foreground mb-4">Details</h3>
          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <User className="h-4 w-4 text-muted-foreground mt-0.5" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Requester</p>
                <p className="text-sm text-foreground">Platform Compliance Bot</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <User className="h-4 w-4 text-muted-foreground mt-0.5" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Assigned To</p>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground">Unassigned</span>
                  <button className="text-xs text-primary hover:underline">Assign to me</button>
                </div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <Clock className="h-4 w-4 text-muted-foreground mt-0.5" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Created</p>
                <p className="text-sm text-foreground">Dec 9, 2024 at 2:34 PM</p>
                <p className="text-xs text-muted-foreground">2 hours ago</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <Folder className="h-4 w-4 text-muted-foreground mt-0.5" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Category</p>
                <p className="text-sm text-foreground">Infrastructure › Compute › Instance Migration</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <Tag className="h-4 w-4 text-muted-foreground mt-0.5" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Change Type</p>
                <Badge variant="success" className="mt-1">Standard Change</Badge>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <LinkIcon className="h-4 w-4 text-muted-foreground mt-0.5" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Related Standard</p>
                <a href="#" className="text-sm text-primary hover:underline">PS-2024-003</a>
              </div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="rounded-lg border border-border bg-card p-5">
          <h3 className="text-sm font-semibold text-foreground mb-4">Actions</h3>
          <div className="space-y-2">
            <Button className="w-full" size="sm">
              Accept & Assign to Me
            </Button>
            <Button variant="outline" className="w-full" size="sm">
              Escalate to CAB
            </Button>
            <Button variant="ghost" className="w-full text-muted-foreground" size="sm">
              Close as Invalid
            </Button>
          </div>
        </div>

        {/* Related Items */}
        <div className="rounded-lg border border-border bg-card p-5">
          <h3 className="text-sm font-semibold text-foreground mb-4">Related Items</h3>
          <div className="space-y-2 text-sm">
            <a href="#" className="block text-primary hover:underline">SC-0042: Instance Migration Template</a>
            <a href="#" className="block text-primary hover:underline">PS-2024-003: Platform Standards</a>
            <a href="#" className="block text-primary hover:underline">CMDB: api-prod-server</a>
          </div>
        </div>
      </div>
    </div>
  );
}
