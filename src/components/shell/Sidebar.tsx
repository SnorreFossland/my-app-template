"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Separator } from "@/components/ui/separator";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export const sidebarLinks = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/overview", label: "Overview" },
  { href: "/features", label: "Features" },
  { href: "/analytics", label: "Analytics" },
  { href: "/settings", label: "Settings" },
  { href: "/about", label: "About" },
];

export const sidebarAccountLinks = [
  { href: "/login", label: "Login" },
  { href: "/signup", label: "Sign up" },
];

export function SidebarContent({ className }: { className?: string }) {
  const pathname = usePathname();

  return (
    <div className={cn("space-y-4", className)}>
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">About this project</CardTitle>
          <CardDescription>A short primer on the architecture and goals.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3 text-sm text-muted-foreground">
          <p>
            This workspace uses Next.js with the App Router, leaning on shadcn/ui primitives to keep the UI cohesive,
            accessible, and easy to extend. The navigation pattern mirrors a typical SaaS dashboard with both tabbed
            primary navigation and a contextual sidebar.
          </p>
          <p>
            Persistence is handled through Prisma, while authentication is powered by NextAuth—already wired with a
            credentials provider so you can plug in your own user logic. The structure is intentionally lightweight so
            you can evolve it into a production application or a rapid prototype.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export default function Sidebar() {
  return (
    <aside className="hidden w-56 shrink-0 border-r bg-background/50 p-4 sm:block">
      <SidebarContent />
    </aside>
  );
}
