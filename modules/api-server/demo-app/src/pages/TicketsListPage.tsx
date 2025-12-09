import { Link } from "react-router-dom";
import { Layout } from "@/components/layout/Layout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Clock, ExternalLink, Filter, Search } from "lucide-react";

const tickets = [
  {
    id: "INFRA-4721",
    title: "Migrate non-compliant c5.large instance to t3 platform standard",
    status: "Open",
    priority: "Low",
    type: "Standard Change",
    requester: "Platform Compliance Bot",
    created: "2 hours ago",
    category: "Infrastructure > Compute",
  },
  {
    id: "INFRA-4720",
    title: "Security group update for web-frontend-prod",
    status: "Closed",
    priority: "Medium",
    type: "Standard Change",
    requester: "Network Team",
    created: "1 day ago",
    category: "Infrastructure > Security",
  },
  {
    id: "INFRA-4719",
    title: "Add additional EBS volume to db-replica-01",
    status: "Closed",
    priority: "High",
    type: "Normal Change",
    requester: "Database Team",
    created: "2 days ago",
    category: "Infrastructure > Storage",
  },
  {
    id: "INFRA-4718",
    title: "Update IAM policies for CI/CD pipeline",
    status: "Closed",
    priority: "Medium",
    type: "Standard Change",
    requester: "DevOps Team",
    created: "3 days ago",
    category: "Infrastructure > IAM",
  },
];

const TicketsListPage = () => {
  return (
    <Layout>
      <div className="p-6">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-semibold text-foreground">Tickets</h1>
            <p className="text-sm text-muted-foreground mt-1">
              View and manage infrastructure change requests
            </p>
          </div>
          <Button>Create Ticket</Button>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-3 mb-6">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search tickets..."
              className="w-full pl-9 pr-4 py-2 rounded-md border border-input bg-background text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            />
          </div>
          <Button variant="outline" size="sm" className="gap-2">
            <Filter className="h-4 w-4" />
            Filters
          </Button>
        </div>

        {/* Tickets List */}
        <div className="rounded-lg border border-border bg-card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-table-header border-b border-table-border">
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Ticket</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Status</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Priority</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Type</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Requester</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Created</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-table-border">
                {tickets.map((ticket) => (
                  <tr key={ticket.id} className="hover:bg-table-hover transition-colors">
                    <td className="px-5 py-4">
                      <div>
                        <Link 
                          to={`/tickets/${ticket.id}`}
                          className="text-sm font-medium text-primary hover:underline"
                        >
                          {ticket.id}
                        </Link>
                        <p className="text-sm text-foreground mt-0.5 line-clamp-1">
                          {ticket.title}
                        </p>
                        <p className="text-xs text-muted-foreground mt-0.5">
                          {ticket.category}
                        </p>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <Badge variant={ticket.status === "Open" ? "info" : "neutral"}>
                        {ticket.status}
                      </Badge>
                    </td>
                    <td className="px-5 py-4">
                      <Badge 
                        variant={
                          ticket.priority === "High" ? "error" : 
                          ticket.priority === "Medium" ? "warning" : 
                          "neutral"
                        }
                      >
                        {ticket.priority}
                      </Badge>
                    </td>
                    <td className="px-5 py-4">
                      <Badge variant="success">{ticket.type}</Badge>
                    </td>
                    <td className="px-5 py-4 text-sm text-muted-foreground">
                      {ticket.requester}
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
                        <Clock className="h-3.5 w-3.5" />
                        {ticket.created}
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <Link to={`/tickets/${ticket.id}`}>
                        <Button variant="ghost" size="sm" className="gap-1.5">
                          View
                          <ExternalLink className="h-3.5 w-3.5" />
                        </Button>
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default TicketsListPage;
