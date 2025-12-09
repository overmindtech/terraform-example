import { Link, useLocation } from "react-router-dom";
import { Layers, LayoutDashboard, Ticket, BookOpen, FileBarChart, Bell, ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import dylanAvatar from "@/assets/dylan-avatar.png";

const navigation = [
  { name: "Dashboard", href: "/", icon: LayoutDashboard },
  { name: "Tickets", href: "/tickets", icon: Ticket },
  { name: "Standards", href: "/standards", icon: BookOpen },
  { name: "Reports", href: "/reports", icon: FileBarChart },
];

export function Header() {
  const location = useLocation();

  return (
    <header className="header-elevated sticky top-0 z-50 w-full">
      <div className="flex h-16 items-center px-6">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-3 mr-10 group">
          <div className="relative flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[hsl(250,83%,60%)] shadow-lg shadow-primary/25 transition-transform group-hover:scale-105">
            <Layers className="h-5 w-5 text-primary-foreground" />
            <div className="absolute inset-0 rounded-xl bg-gradient-to-t from-transparent to-white/20" />
          </div>
          <span className="font-semibold text-foreground text-lg tracking-tight">Stratum</span>
        </Link>

        {/* Navigation */}
        <nav className="flex items-center gap-1">
          {navigation.map((item) => {
            const isActive = location.pathname === item.href || 
              (item.href !== "/" && location.pathname.startsWith(item.href));
            
            return (
              <Link
                key={item.name}
                to={item.href}
                className={cn(
                  "nav-item",
                  isActive
                    ? "active"
                    : "text-muted-foreground hover:text-foreground hover:bg-muted/50"
                )}
              >
                <item.icon className="h-4 w-4" />
                {item.name}
              </Link>
            );
          })}
        </nav>

        {/* Right side */}
        <div className="ml-auto flex items-center gap-3">
          {/* Notifications */}
          <button className="relative p-2.5 text-muted-foreground hover:text-foreground hover:bg-muted rounded-xl transition-all duration-200 hover:shadow-sm">
            <Bell className="h-5 w-5" />
            <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-destructive ring-2 ring-header" />
          </button>

          {/* User */}
          <button className="flex items-center gap-3 px-3 py-2 rounded-xl hover:bg-muted transition-all duration-200 hover:shadow-sm">
            <img 
              src={dylanAvatar} 
              alt="Dylan Ratcliffe" 
              className="h-9 w-9 rounded-xl object-cover ring-2 ring-border shadow-sm"
            />
            <div className="text-left hidden sm:block">
              <p className="text-sm font-medium text-foreground">Dylan Ratcliffe</p>
              <p className="text-xs text-muted-foreground">Platform Engineering</p>
            </div>
            <ChevronDown className="h-4 w-4 text-muted-foreground hidden sm:block" />
          </button>
        </div>
      </div>
    </header>
  );
}
