import { Server, CheckCircle2, XCircle, Clock } from "lucide-react";
import { Layout } from "@/components/layout/Layout";
import { ComplianceGauge } from "@/components/dashboard/ComplianceGauge";
import { StatCard } from "@/components/dashboard/StatCard";
import { InstancesTable } from "@/components/dashboard/InstancesTable";

const Index = () => {
  return (
    <Layout>
      <div className="p-8 lg:p-10">
        {/* Page Header */}
        <div className="mb-8 animate-fade-in">
          <h1 className="text-2xl font-bold text-foreground tracking-tight">Compliance Dashboard</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Real-time infrastructure compliance monitoring across all environments
          </p>
        </div>

        <div className="space-y-6">
          {/* Stats Row */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Compliance Score */}
            <div className="card-elevated p-6 flex flex-col items-center justify-center animate-scale-in">
              <p className="text-sm font-medium text-muted-foreground mb-4">Overall Compliance</p>
              <ComplianceGauge score={97.9} visualProgress={92} size="lg" />
              <p className="text-xs text-muted-foreground mt-4 text-center">
                Last scan: 3 hours ago
              </p>
            </div>

            {/* Stat Cards - 2x2 Grid */}
            <div className="lg:col-span-2 grid grid-cols-2 gap-4">
              <div className="animate-slide-up" style={{ animationDelay: "0.05s" }}>
                <StatCard
                  title="Total Instances"
                  value={48}
                  icon={Server}
                  variant="default"
                />
              </div>
              <div className="animate-slide-up" style={{ animationDelay: "0.1s" }}>
                <StatCard
                  title="Compliant"
                  value={47}
                  icon={CheckCircle2}
                  variant="success"
                />
              </div>
              <div className="animate-slide-up" style={{ animationDelay: "0.15s" }}>
                <StatCard
                  title="Non-Compliant"
                  value={1}
                  icon={XCircle}
                  variant="error"
                  pulse
                />
              </div>
              <div className="animate-slide-up" style={{ animationDelay: "0.2s" }}>
                <StatCard
                  title="Pending Review"
                  value={0}
                  icon={Clock}
                  variant="default"
                />
              </div>
            </div>
          </div>

          {/* Instances Table */}
          <InstancesTable />
        </div>
      </div>
    </Layout>
  );
};

export default Index;
