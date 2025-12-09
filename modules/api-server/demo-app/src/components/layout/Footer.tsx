export function Footer() {
  return (
    <footer className="border-t border-border bg-card/50 backdrop-blur-sm py-4 px-6">
      <div className="flex items-center justify-between text-xs text-muted-foreground">
        <div className="flex items-center gap-2">
          <span className="h-1.5 w-1.5 rounded-full bg-success animate-pulse" />
          <span>Demo Environment - Stratum v2.4.1</span>
        </div>
        <span>© 2024 Stratum Technologies. All rights reserved.</span>
      </div>
    </footer>
  );
}
