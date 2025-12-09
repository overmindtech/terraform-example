import { cn } from "@/lib/utils";

interface ComplianceGaugeProps {
  score: number;
  visualProgress?: number; // Optional override for visual progress
  size?: "sm" | "md" | "lg";
}

export function ComplianceGauge({ score, visualProgress, size = "lg" }: ComplianceGaugeProps) {
  const displayProgress = visualProgress ?? score;
  const radius = size === "lg" ? 70 : size === "md" ? 55 : 38;
  const strokeWidth = size === "lg" ? 14 : size === "md" ? 12 : 10;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (displayProgress / 100) * circumference;

  const getScoreColor = (score: number) => {
    if (score >= 95) return "text-success";
    if (score >= 80) return "text-warning";
    return "text-destructive";
  };

  const getStrokeColor = (score: number) => {
    if (score >= 95) return "stroke-success";
    if (score >= 80) return "stroke-warning";
    return "stroke-destructive";
  };

  const dimensions = {
    sm: { viewBox: 100, textSize: "text-lg", labelSize: "text-xs" },
    md: { viewBox: 140, textSize: "text-2xl", labelSize: "text-xs" },
    lg: { viewBox: 180, textSize: "text-4xl", labelSize: "text-sm" },
  };

  const { viewBox, textSize, labelSize } = dimensions[size];
  const center = viewBox / 2;

  return (
    <div className="relative inline-flex items-center justify-center">
      <svg
        width={viewBox}
        height={viewBox}
        viewBox={`0 0 ${viewBox} ${viewBox}`}
        className="transform -rotate-90"
      >
        {/* Background circle */}
        <circle
          cx={center}
          cy={center}
          r={radius}
          fill="none"
          strokeWidth={strokeWidth}
          className="stroke-border"
          strokeLinecap="round"
        />
        {/* Gradient definition */}
        <defs>
          <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="hsl(152, 69%, 40%)" />
            <stop offset="100%" stopColor="hsl(152, 69%, 50%)" />
          </linearGradient>
        </defs>
        {/* Progress circle */}
        <circle
          cx={center}
          cy={center}
          r={radius}
          fill="none"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          className={cn("transition-all duration-1000 ease-out", getStrokeColor(score))}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className={cn("font-bold tracking-tight", textSize, getScoreColor(score))}>
          {score.toFixed(1)}%
        </span>
        <span className={cn("text-muted-foreground font-medium", labelSize)}>Compliant</span>
      </div>
    </div>
  );
}
