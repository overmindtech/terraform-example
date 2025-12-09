import { useParams, Link } from "react-router-dom";
import { ChevronRight, ArrowLeft } from "lucide-react";
import { Layout } from "@/components/layout/Layout";
import { TicketDetail } from "@/components/tickets/TicketDetail";
import { Button } from "@/components/ui/button";

const TicketPage = () => {
  const { ticketId } = useParams<{ ticketId: string }>();

  return (
    <Layout>
      <div className="p-6">
        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
          <Link to="/tickets" className="hover:text-foreground transition-colors">
            Tickets
          </Link>
          <ChevronRight className="h-4 w-4" />
          <span className="text-foreground font-medium">{ticketId}</span>
        </div>

        {/* Back Button */}
        <Link to="/">
          <Button variant="ghost" size="sm" className="mb-4 -ml-2 gap-1.5">
            <ArrowLeft className="h-4 w-4" />
            Back to Dashboard
          </Button>
        </Link>

        <TicketDetail ticketId={ticketId || "INFRA-4721"} />
      </div>
    </Layout>
  );
};

export default TicketPage;
