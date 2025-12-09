import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  variant?: "default" | "success" | "warning" | "error";
  pulse?: boolean;
}

export function StatCard({ title, value, icon: Icon, variant = "default", pulse = false }: StatCardProps) {
  const iconVariants = {
    default: "bg-primary/10 text-primary",
    success: "bg-success/10 text-success",
    warning: "bg-warning/10 text-warning",
    error: "bg-destructive/10 text-destructive",
  };

  const valueVariants = {
    default: "text-foreground",
    success: "text-success",
    warning: "text-warning",
    error: "text-destructive",
  };

  const cardClass = cn(
    "stat-card",
    variant === "success" && "stat-card-success",
    variant === "error" && "stat-card-error",
    pulse && variant === "error" && "pulse-glow glow-error"
  );

  return (
    <div className={cardClass}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <p className={cn("mt-2 text-3xl font-bold tracking-tight", valueVariants[variant])}>
            {value}
          </p>
        </div>
        <div className={cn("rounded-xl p-3 transition-transform hover:scale-110", iconVariants[variant])}>
          <Icon className="h-5 w-5" />
        </div>
      </div>
    </div>
  );
}
