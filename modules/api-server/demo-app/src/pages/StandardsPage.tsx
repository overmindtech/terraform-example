import { Layout } from "@/components/layout/Layout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { BookOpen, CheckCircle2, ExternalLink, Search } from "lucide-react";

const standards = [
  {
    id: "PS-2024-003",
    title: "EC2 Instance Family Standards",
    description: "All EC2 instances must use t3 instance family to leverage pre-purchased Savings Plans.",
    category: "Compute",
    status: "Active",
    affectedResources: 48,
    complianceRate: 97.9,
    lastUpdated: "Nov 15, 2024",
  },
  {
    id: "PS-2024-002",
    title: "S3 Bucket Encryption Requirements",
    description: "All S3 buckets must have server-side encryption enabled with AES-256 or AWS KMS.",
    category: "Storage",
    status: "Active",
    affectedResources: 127,
    complianceRate: 100,
    lastUpdated: "Oct 22, 2024",
  },
  {
    id: "PS-2024-001",
    title: "VPC Security Group Standards",
    description: "Security groups must not allow unrestricted inbound access (0.0.0.0/0) on sensitive ports.",
    category: "Security",
    status: "Active",
    affectedResources: 89,
    complianceRate: 100,
    lastUpdated: "Sep 10, 2024",
  },
  {
    id: "PS-2023-015",
    title: "RDS Instance Configuration",
    description: "All RDS instances must have Multi-AZ enabled for production environments.",
    category: "Database",
    status: "Active",
    affectedResources: 12,
    complianceRate: 100,
    lastUpdated: "Aug 5, 2024",
  },
];

const StandardsPage = () => {
  return (
    <Layout>
      <div className="p-6">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-semibold text-foreground">Platform Standards</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Infrastructure compliance policies and requirements
            </p>
          </div>
          <Button>Create Standard</Button>
        </div>

        {/* Search */}
        <div className="relative max-w-md mb-6">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search standards..."
            className="w-full pl-9 pr-4 py-2 rounded-md border border-input bg-background text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          />
        </div>

        {/* Standards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {standards.map((standard) => (
            <div
              key={standard.id}
              className="rounded-lg border border-border bg-card p-5 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between gap-4 mb-3">
                <div className="flex items-center gap-2">
                  <div className="p-2 rounded-lg bg-primary/10">
                    <BookOpen className="h-4 w-4 text-primary" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-mono">{standard.id}</p>
                    <h3 className="text-sm font-semibold text-foreground">{standard.title}</h3>
                  </div>
                </div>
                <Badge variant="success">{standard.status}</Badge>
              </div>

              <p className="text-sm text-muted-foreground mb-4">{standard.description}</p>

              <div className="grid grid-cols-3 gap-4 mb-4">
                <div>
                  <p className="text-xs text-muted-foreground">Category</p>
                  <Badge variant="neutral" className="mt-1">{standard.category}</Badge>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Resources</p>
                  <p className="text-sm font-medium text-foreground">{standard.affectedResources}</p>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Compliance</p>
                  <div className="flex items-center gap-1">
                    {standard.complianceRate === 100 ? (
                      <CheckCircle2 className="h-4 w-4 text-success" />
                    ) : null}
                    <span className={`text-sm font-medium ${
                      standard.complianceRate === 100 ? "text-success" : "text-warning"
                    }`}>
                      {standard.complianceRate}%
                    </span>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-border">
                <p className="text-xs text-muted-foreground">Updated: {standard.lastUpdated}</p>
                <Button variant="ghost" size="sm" className="gap-1.5">
                  View Details
                  <ExternalLink className="h-3.5 w-3.5" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Layout>
  );
};

export default StandardsPage;
