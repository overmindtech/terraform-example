import { Layout } from "@/components/layout/Layout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Calendar, Download, FileBarChart, TrendingUp } from "lucide-react";

const reports = [
  {
    id: "RPT-2024-12-09",
    title: "Monthly Compliance Summary - December 2024",
    type: "Compliance",
    status: "Generated",
    generatedAt: "Dec 9, 2024 at 3:00 AM",
    size: "2.4 MB",
  },
  {
    id: "RPT-2024-11-30",
    title: "Monthly Compliance Summary - November 2024",
    type: "Compliance",
    status: "Generated",
    generatedAt: "Nov 30, 2024 at 3:00 AM",
    size: "2.1 MB",
  },
  {
    id: "RPT-2024-Q3",
    title: "Quarterly Cost Analysis - Q3 2024",
    type: "Cost",
    status: "Generated",
    generatedAt: "Oct 1, 2024 at 6:00 AM",
    size: "4.7 MB",
  },
  {
    id: "RPT-2024-AUDIT",
    title: "Annual Security Audit Report 2024",
    type: "Audit",
    status: "Generated",
    generatedAt: "Sep 15, 2024 at 12:00 PM",
    size: "8.3 MB",
  },
];

const ReportsPage = () => {
  return (
    <Layout>
      <div className="p-6">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl font-semibold text-foreground">Reports</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Compliance reports and analytics
            </p>
          </div>
          <Button>Generate Report</Button>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
          <div className="rounded-lg border border-border bg-card p-5">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-lg bg-success/10">
                <TrendingUp className="h-5 w-5 text-success" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Avg. Compliance Rate</p>
                <p className="text-2xl font-semibold text-foreground">98.2%</p>
              </div>
            </div>
          </div>
          <div className="rounded-lg border border-border bg-card p-5">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-lg bg-primary/10">
                <FileBarChart className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Reports Generated</p>
                <p className="text-2xl font-semibold text-foreground">47</p>
              </div>
            </div>
          </div>
          <div className="rounded-lg border border-border bg-card p-5">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-lg bg-info/10">
                <Calendar className="h-5 w-5 text-info" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Next Scheduled</p>
                <p className="text-2xl font-semibold text-foreground">Dec 31</p>
              </div>
            </div>
          </div>
        </div>

        {/* Reports List */}
        <div className="rounded-lg border border-border bg-card overflow-hidden">
          <div className="px-5 py-4 border-b border-border">
            <h3 className="text-base font-semibold text-foreground">Recent Reports</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-table-header border-b border-table-border">
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Report</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Type</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Status</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Generated</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Size</th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-table-border">
                {reports.map((report) => (
                  <tr key={report.id} className="hover:bg-table-hover transition-colors">
                    <td className="px-5 py-4">
                      <div>
                        <p className="text-xs text-muted-foreground font-mono">{report.id}</p>
                        <p className="text-sm font-medium text-foreground">{report.title}</p>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <Badge variant="neutral">{report.type}</Badge>
                    </td>
                    <td className="px-5 py-4">
                      <Badge variant="success">{report.status}</Badge>
                    </td>
                    <td className="px-5 py-4 text-sm text-muted-foreground">
                      {report.generatedAt}
                    </td>
                    <td className="px-5 py-4 text-sm text-muted-foreground">
                      {report.size}
                    </td>
                    <td className="px-5 py-4">
                      <Button variant="outline" size="sm" className="gap-1.5">
                        <Download className="h-3.5 w-3.5" />
                        Download
                      </Button>
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

export default ReportsPage;
