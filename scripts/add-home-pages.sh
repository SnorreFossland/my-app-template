#!/usr/bin/env bash
set -euo pipefail

cd "${1:-my-app}"
# Regenerates the current dashboard scaffold (navigation, pages, auth, store, and API routes)
# using shadcn/ui primitives plus local theme, auth, and Redux helpers.

# 1) Ensure the shadcn/ui components we depend on exist (no-op if already added)
pnpm dlx shadcn@latest add button card input label dropdown-menu navigation-menu separator || true

# 2) Shared directories
mkdir -p \
  src/lib \
  src/auth \
  src/store/slices \
  src/store/services \
  src/components/shell \
  src/components/ui \
  src/components/theme \
  "src/app/(main)/overview" \
  "src/app/(main)/features" \
  "src/app/(main)/analytics" \
  "src/app/(main)/settings" \
  "src/app/(main)/about" \
  "src/app/(auth)/login" \
  "src/app/(auth)/signup" \
  src/app/api/ping \
  src/app/api/signup \
  "src/app/api/auth/[...nextauth]"

# 3) Utilities
cat > src/lib/utils.ts <<'EOF'
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

# 4) Shell components
cat > src/components/shell/Sidebar.tsx <<'EOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Separator } from "@/components/ui/separator";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export const sidebarLinks = [
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
EOF

cat > src/components/shell/TopNav.tsx <<'EOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  NavigationMenu,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
} from "@/components/ui/navigation-menu";
import { cn } from "@/lib/utils";
import { sidebarLinks } from "./Sidebar";
import { ThemeToggle } from "@/components/theme/theme-toggle";

export default function TopNav() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-40 w-full border-b bg-background/80 backdrop-blur">
      <div className="mx-auto flex h-16 w-full max-w-7xl items-center gap-4 px-4">
        <div className="flex items-center gap-3">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button aria-label="Open navigation" className="-m-2 p-2 rounded hover:bg-muted/50">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
                  <path d="M3 12h18" />
                  <path d="M3 6h18" />
                  <path d="M3 18h18" />
                </svg>
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuLabel>Navigate</DropdownMenuLabel>
              <DropdownMenuSeparator />
              {sidebarLinks.map((link) => (
                <DropdownMenuItem asChild key={link.href}>
                  <Link href={link.href}>{link.label}</Link>
                </DropdownMenuItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
          <Link href="/overview" className="shrink-0 text-lg font-semibold">
            My App
          </Link>
        </div>
        <NavigationMenu className="max-w-none flex-1 justify-start">
          <NavigationMenuList className="flex w-full items-center gap-2 overflow-x-auto">
            {sidebarLinks.map((link) => {
              const isActive = pathname === link.href || (pathname === "/" && link.href === "/overview");
              return (
                <NavigationMenuItem key={link.href}>
                  <NavigationMenuLink asChild>
                    <Link
                      href={link.href}
                      className={cn(
                        "inline-flex items-center rounded-md px-3 py-2 text-sm font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                        isActive
                          ? "bg-primary/10 text-primary shadow-sm"
                          : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                      )}
                      aria-current={isActive ? "page" : undefined}
                    >
                      {link.label}
                    </Link>
                  </NavigationMenuLink>
                </NavigationMenuItem>
              );
            })}
          </NavigationMenuList>
        </NavigationMenu>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" size="sm">
              Account
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>My Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem asChild>
              <Link href="/login">Login</Link>
            </DropdownMenuItem>
            <DropdownMenuItem asChild>
              <Link href="/signup">Sign up</Link>
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem asChild>
              <Link href="/dashboard">Dashboard</Link>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        <div className="ml-2 flex items-center">
          <ThemeToggle />
        </div>
      </div>
    </header>
  );
}
EOF

# Theme options and mapping
cat > src/components/theme/themes.ts <<'EOF'
export type ThemeOption = {
  value: string;
  label: string;
  className?: string;
  group?: string;
};

export const themeOptions: ThemeOption[] = [
  { value: "light", label: "Default Light", className: "light", group: "Default" },
  { value: "dark", label: "Default Dark", className: "dark", group: "Default" },
  { value: "forest", label: "Forest Light", className: "theme-forest", group: "Forest" },
  { value: "forest-dark", label: "Forest Dark", className: "theme-forest-dark", group: "Forest" },
  { value: "ocean", label: "Ocean Light", className: "theme-ocean", group: "Ocean" },
  { value: "ocean-dark", label: "Ocean Dark", className: "theme-ocean-dark", group: "Ocean" },
  { value: "sunset", label: "Sunset Light", className: "theme-sunset", group: "Sunset" },
  { value: "sunset-dark", label: "Sunset Dark", className: "theme-sunset-dark", group: "Sunset" },
  { value: "system", label: "System" },
];

export const themeClassMap = themeOptions.reduce<Record<string, string>>((acc, option) => {
  if (option.className) {
    acc[option.value] = option.className;
  }
  return acc;
}, {});
EOF



cat > src/app/page.tsx <<'EOF'
import { redirect } from "next/navigation";

export default function IndexPage() {
  redirect("/overview");
}
EOF

cat > src/app/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --border: 222 12% 90%;
  --input: 0 0% 100%;
  --ring: 222 89% 53%;
  --background: 0 0% 100%;
  --foreground: 222 47% 11%;
  --primary: 222 89% 53%;
  --primary-foreground: 0 0% 100%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222 47% 11%;
  --destructive: 0 84% 60%;
  --destructive-foreground: 0 0% 100%;
  --muted: 210 40% 96%;
  --muted-foreground: 215 20% 35%;
  --accent: 222 89% 53%;
  --accent-foreground: 0 0% 100%;
  --popover: 0 0% 100%;
  --popover-foreground: 222 47% 11%;
  --card: 0 0% 100%;
  --card-foreground: 222 47% 11%;
  --chart-1: 222 89% 53%;
  --chart-2: 4 90% 58%;
  --chart-3: 43 90% 55%;
  --chart-4: 142 71% 45%;
  --chart-5: 199 89% 48%;
  color-scheme: light;
  font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif;
}

.dark {
  --border: 217 33% 17%;
  --input: 217 33% 17%;
  --ring: 222 89% 53%;
  --background: 222 47% 11%;
  --foreground: 210 40% 98%;
  --primary: 222 89% 53%;
  --primary-foreground: 0 0% 100%;
  --secondary: 217 33% 17%;
  --secondary-foreground: 210 40% 98%;
  --destructive: 0 84% 60%;
  --destructive-foreground: 0 0% 100%;
  --muted: 217 33% 17%;
  --muted-foreground: 215 20% 65%;
  --accent: 222 89% 53%;
  --accent-foreground: 0 0% 100%;
  --popover: 222 47% 11%;
  --popover-foreground: 210 40% 98%;
  --card: 222 47% 11%;
  --card-foreground: 210 40% 98%;
  --chart-1: 222 89% 70%;
  --chart-2: 4 90% 62%;
  --chart-3: 43 90% 65%;
  --chart-4: 142 71% 55%;
  --chart-5: 199 89% 60%;
  color-scheme: dark;
}

.theme-forest {
  --border: 125 20% 78%;
  --input: 120 22% 96%;
  --ring: 142 71% 45%;
  --background: 120 22% 96%;
  --foreground: 152 24% 16%;
  --primary: 142 71% 45%;
  --primary-foreground: 0 0% 100%;
  --secondary: 122 27% 90%;
  --secondary-foreground: 152 24% 16%;
  --destructive: 0 74% 54%;
  --destructive-foreground: 0 0% 100%;
  --muted: 122 18% 85%;
  --muted-foreground: 152 16% 30%;
  --accent: 171 45% 40%;
  --accent-foreground: 0 0% 100%;
  --popover: 120 22% 98%;
  --popover-foreground: 152 24% 16%;
  --card: 120 22% 98%;
  --card-foreground: 152 24% 16%;
  --chart-1: 142 71% 45%;
  --chart-2: 171 45% 40%;
  --chart-3: 94 48% 54%;
  --chart-4: 26 74% 55%;
  --chart-5: 352 63% 52%;
  color-scheme: light;
}

.theme-forest-dark {
  --border: 151 22% 24%;
  --input: 151 22% 24%;
  --ring: 142 71% 45%;
  --background: 149 30% 12%;
  --foreground: 122 60% 92%;
  --primary: 142 61% 50%;
  --primary-foreground: 125 30% 12%;
  --secondary: 153 23% 18%;
  --secondary-foreground: 122 60% 92%;
  --destructive: 0 74% 54%;
  --destructive-foreground: 0 0% 100%;
  --muted: 153 17% 24%;
  --muted-foreground: 128 20% 72%;
  --accent: 169 46% 45%;
  --accent-foreground: 125 30% 12%;
  --popover: 149 30% 16%;
  --popover-foreground: 122 60% 92%;
  --card: 149 30% 16%;
  --card-foreground: 122 60% 92%;
  --chart-1: 142 61% 50%;
  --chart-2: 169 46% 45%;
  --chart-3: 94 48% 58%;
  --chart-4: 26 74% 58%;
  --chart-5: 352 63% 56%;
  color-scheme: dark;
}

.theme-ocean {
  --border: 204 34% 78%;
  --input: 199 97% 97%;
  --ring: 199 89% 48%;
  --background: 199 97% 97%;
  --foreground: 210 34% 18%;
  --primary: 199 89% 48%;
  --primary-foreground: 0 0% 100%;
  --secondary: 197 81% 92%;
  --secondary-foreground: 210 34% 18%;
  --destructive: 353 74% 55%;
  --destructive-foreground: 0 0% 100%;
  --muted: 200 53% 88%;
  --muted-foreground: 208 23% 35%;
  --accent: 187 82% 45%;
  --accent-foreground: 0 0% 100%;
  --popover: 199 97% 99%;
  --popover-foreground: 210 34% 18%;
  --card: 199 97% 99%;
  --card-foreground: 210 34% 18%;
  --chart-1: 199 89% 48%;
  --chart-2: 187 82% 45%;
  --chart-3: 212 84% 60%;
  --chart-4: 153 47% 47%;
  --chart-5: 20 89% 60%;
  color-scheme: light;
}

.theme-ocean-dark {
  --border: 207 26% 30%;
  --input: 207 26% 30%;
  --ring: 199 89% 58%;
  --background: 214 35% 12%;
  --foreground: 202 74% 92%;
  --primary: 199 89% 58%;
  --primary-foreground: 212 35% 16%;
  --secondary: 212 28% 20%;
  --secondary-foreground: 202 74% 92%;
  --destructive: 353 74% 62%;
  --destructive-foreground: 0 0% 100%;
  --muted: 208 22% 26%;
  --muted-foreground: 202 40% 70%;
  --accent: 187 82% 54%;
  --accent-foreground: 214 35% 12%;
  --popover: 214 35% 16%;
  --popover-foreground: 202 74% 92%;
  --card: 214 35% 16%;
  --card-foreground: 202 74% 92%;
  --chart-1: 199 89% 58%;
  --chart-2: 187 82% 54%;
  --chart-3: 212 84% 65%;
  --chart-4: 153 47% 55%;
  --chart-5: 20 89% 66%;
  color-scheme: dark;
}

.theme-sunset {
  --border: 24 28% 82%;
  --input: 25 80% 96%;
  --ring: 17 90% 55%;
  --background: 25 80% 96%;
  --foreground: 12 42% 20%;
  --primary: 17 90% 55%;
  --primary-foreground: 0 0% 100%;
  --secondary: 33 100% 88%;
  --secondary-foreground: 12 42% 20%;
  --destructive: 353 74% 55%;
  --destructive-foreground: 0 0% 100%;
  --muted: 31 52% 82%;
  --muted-foreground: 18 46% 35%;
  --accent: 326 70% 58%;
  --accent-foreground: 0 0% 100%;
  --popover: 25 80% 98%;
  --popover-foreground: 12 42% 20%;
  --card: 25 80% 98%;
  --card-foreground: 12 42% 20%;
  --chart-1: 17 90% 55%;
  --chart-2: 326 70% 58%;
  --chart-3: 204 90% 55%;
  --chart-4: 142 71% 45%;
  --chart-5: 44 85% 55%;
  color-scheme: light;
}

.theme-sunset-dark {
  --border: 18 60% 28%;
  --input: 18 60% 28%;
  --ring: 17 90% 65%;
  --background: 20 64% 12%;
  --foreground: 27 53% 92%;
  --primary: 17 83% 63%;
  --primary-foreground: 20 64% 12%;
  --secondary: 28 58% 20%;
  --secondary-foreground: 27 53% 92%;
  --destructive: 353 74% 62%;
  --destructive-foreground: 0 0% 100%;
  --muted: 21 48% 24%;
  --muted-foreground: 26 38% 72%;
  --accent: 329 69% 64%;
  --accent-foreground: 20 64% 12%;
  --popover: 20 64% 16%;
  --popover-foreground: 27 53% 92%;
  --card: 20 64% 16%;
  --card-foreground: 27 53% 92%;
  --chart-1: 17 83% 63%;
  --chart-2: 329 69% 64%;
  --chart-3: 204 90% 60%;
  --chart-4: 142 71% 55%;
  --chart-5: 44 85% 60%;
  color-scheme: dark;
}

@layer base {
  *, ::before, ::after {
    box-sizing: border-box;
  }

  * {
    border-color: hsl(var(--border));
  }

  body {
    background-color: hsl(var(--background));
    color: hsl(var(--foreground));
  }
}

.test-bg {
  background-color: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
  padding: 1rem;
}
EOF

# 7) Main layout and pages
cat > "src/app/(main)/layout.tsx" <<'EOF'
import type { ReactNode } from "react";
import TopNav from "@/components/shell/TopNav";
import Sidebar from "@/components/shell/Sidebar";
import { TailwindForce } from "@/components/ui/tailwind-force";

export default function MainLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh bg-background">
      <TopNav />
      <div className="mx-auto flex w-full max-w-7xl gap-6 px-4 py-6">
        <Sidebar />
        <main className="flex-1 space-y-6">{children}</main>
        <TailwindForce />
      </div>
    </div>
  );
}
EOF

cat > "src/app/(main)/overview/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export default function OverviewPage() {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Welcome back</CardTitle>
          <CardDescription>High-level snapshot of your workspace.</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap items-center gap-3 pt-0">
          <Button size="sm">Invite teammate</Button>
          <Button size="sm" variant="outline">
            View reports
          </Button>
        </CardContent>
      </Card>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Active users</CardTitle>
            <CardDescription>Unique logins this week</CardDescription>
          </CardHeader>
          <CardContent className="pt-0">
            <p className="text-3xl font-semibold">1,284</p>
            <p className="text-sm text-muted-foreground">Up 8% vs last week</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Conversion rate</CardTitle>
            <CardDescription>Sign-ups to paid accounts</CardDescription>
          </CardHeader>
          <CardContent className="pt-0">
            <p className="text-3xl font-semibold">42%</p>
            <p className="text-sm text-muted-foreground">Steady over the past 14 days</p>
          </CardContent>
        </Card>

        <Card className="md:col-span-2 xl:col-span-1">
          <CardHeader>
            <CardTitle>Tasks remaining</CardTitle>
            <CardDescription>Launch checklist for this cycle</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2 pt-0 text-sm text-muted-foreground">
            <p>• QA new billing flow</p>
            <p>• Finalize onboarding emails</p>
            <p>• Prep changelog announcement</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
EOF

cat > "src/app/(main)/features/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

const featureList = [
  {
    title: "Composable UI primitives",
    description: "Leverage shadcn/ui components to build consistent, accessible experiences quickly.",
  },
  {
    title: "Auth-ready setup",
    description: "NextAuth integration with credentials provider gives you a secure starting point.",
  },
  {
    title: "Responsive navigation",
    description: "Top-level tabs and sidebar keep navigation clear across desktop and mobile.",
  },
  {
    title: "TypeScript-first",
    description: "Strict typing across components and utilities reduces runtime surprises.",
  },
];

export default function FeaturesPage() {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Features</CardTitle>
          <CardDescription>Why this starter is a productive baseline.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2">
          {featureList.map((feature) => (
            <div key={feature.title} className="space-y-1 rounded-lg border p-4 text-sm">
              <p className="font-medium text-foreground">{feature.title}</p>
              <p className="text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
EOF

cat > "src/app/(main)/analytics/page.tsx" <<'EOF'
"use client";

import { useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

const MOCK_DATA = {
  weekly: [120, 180, 210, 260, 300, 340, 420],
  monthly: [820, 760, 880, 940, 1010, 980, 1105, 1180, 1250, 1330, 1405, 1500],
};

function formatSeries(series: number[]) {
  const max = Math.max(...series);
  return series.map((value) => Math.round((value / max) * 100));
}

export default function AnalyticsPage() {
  const [range, setRange] = useState<"weekly" | "monthly">("weekly");
  const points = useMemo(() => formatSeries(MOCK_DATA[range]), [range]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Analytics</CardTitle>
          <CardDescription>Simple engagement trends using mocked data.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center gap-2">
            <Button size="sm" variant={range === "weekly" ? "default" : "outline"} onClick={() => setRange("weekly")}>
              Weekly
            </Button>
            <Button size="sm" variant={range === "monthly" ? "default" : "outline"} onClick={() => setRange("monthly")}>
              Monthly
            </Button>
          </div>

          <div className="grid gap-2 text-xs text-muted-foreground md:grid-cols-12">
            {points.map((value, idx) => (
              <div key={idx} className="flex flex-col items-center justify-end gap-2 rounded border bg-muted/20 p-2">
                <div
                  className="w-full rounded bg-primary/70"
                  style={{ height: `${Math.max(value, 10)}%`, minHeight: "2.5rem" }}
                />
                <span className="font-medium text-foreground">{MOCK_DATA[range][idx]}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
EOF

cat > "src/app/(main)/settings/page.tsx" <<'EOF'
"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function SettingsPage() {
  const [name, setName] = useState("Workspace inc.");
  const [email, setEmail] = useState("admin@example.com");

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Settings</CardTitle>
          <CardDescription>Update workspace preferences and contact details.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="workspace-name">Workspace name</Label>
            <Input
              id="workspace-name"
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Enter a name"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="support-email">Support email</Label>
            <Input
              id="support-email"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="team@example.com"
            />
          </div>
          <div className="flex items-center justify-end gap-2">
            <Button variant="outline" size="sm">
              Reset
            </Button>
            <Button size="sm">Save changes</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
EOF

cat > "src/app/(main)/about/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function AboutPage() {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">About this project</CardTitle>
          <CardDescription>A short primer on the architecture and goals.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3 text-sm text-muted-foreground">
          <p>
            This workspace uses Next.js 15 with the App Router, leaning on shadcn/ui primitives to keep the UI cohesive,
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
EOF

# 8) Auth routes
cat > "src/app/(auth)/login/page.tsx" <<'EOF'
"use client";

import { z } from "zod";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

const schema = z.object({ email: z.string().email(), password: z.string().min(6) });

export default function Login() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<{ email: string; password: string }>({ resolver: zodResolver(schema) });

  return (
    <div className="mx-auto max-w-md p-8">
      <Card className="space-y-4 p-6">
        <h2 className="text-xl font-semibold">Login</h2>
        <form
          onSubmit={handleSubmit(async (values) => {
            const response = await signIn("credentials", {
              redirect: false,
              email: values.email,
              password: values.password,
            });

            if (!response || response.error) {
              alert("Invalid credentials");
              return;
            }

            router.push("/dashboard");
          })}
          className="space-y-3"
        >
          <Input type="email" placeholder="Email" {...register("email")} />
          {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          <Input type="password" placeholder="Password" {...register("password")} />
          {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          <Button type="submit" disabled={isSubmitting}>
            Sign in
          </Button>
        </form>
      </Card>
    </div>
  );
}
EOF

cat > "src/app/(auth)/signup/page.tsx" <<'EOF'
"use client";

import { z } from "zod";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

const schema = z.object({
  name: z.string().optional(),
  email: z.string().email(),
  password: z.string().min(6),
});

export default function Signup() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<{ name?: string; email: string; password: string }>({ resolver: zodResolver(schema) });

  return (
    <div className="mx-auto max-w-md p-8">
      <Card className="space-y-4 p-6">
        <h2 className="text-xl font-semibold">Sign up</h2>
        <form
          onSubmit={handleSubmit(async (values) => {
            const res = await fetch("/api/signup", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(values),
            });

            if (!res.ok) {
              const payload = await res.json().catch(() => ({}));
              alert(payload.error ?? "Error creating account");
              return;
            }

            router.push("/login");
          })}
          className="space-y-3"
        >
          <Input placeholder="Name (optional)" {...register("name")} />
          <Input type="email" placeholder="Email" {...register("email")} />
          {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          <Input type="password" placeholder="Password (min 6)" {...register("password")} />
          {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          <Button type="submit" disabled={isSubmitting}>
            Create account
          </Button>
        </form>
      </Card>
    </div>
  );
}
EOF

# 9) Dashboard gate
if [ -f src/app/dashboard/page.tsx ]; then
  echo "src/app/dashboard/page.tsx exists; skipping creation"
else
  cat > src/app/dashboard/page.tsx <<'EOF'
import { auth } from "@/auth/auth";
import { redirect } from "next/navigation";

export default async function Dashboard() {
  const session = await auth();

  if (!session?.user) {
    redirect("/login");
  }

  return (
    <main className="space-y-4 p-8">
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p>Signed in as: {session.user.email}</p>
    </main>
  );
}
EOF
fi

# 10) API routes
cat > src/app/api/ping/route.ts <<'EOF'
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ ok: true });
}
EOF

cat > src/app/api/signup/route.ts <<'EOF'
import bcrypt from "bcryptjs";
import { NextResponse } from "next/server";
import { prisma } from "@/auth/prisma";

export async function POST(req: Request) {
  const { email, password, name } = await req.json().catch(() => ({}));

  if (!email || !password) {
    return NextResponse.json({ error: "Invalid" }, { status: 400 });
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return NextResponse.json({ error: "Exists" }, { status: 409 });
  }

  const hash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({ data: { email, password: hash, name } });

  return NextResponse.json({ id: user.id, email: user.email });
}
EOF

cat > "src/app/api/auth/[...nextauth]/route.ts" <<'EOF'
export { GET, POST } from "@/auth/auth";
EOF

# 11) Auth helpers
cat > src/auth/prisma.ts <<'EOF'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
EOF

cat > src/auth/auth.ts <<'EOF'
import bcrypt from "bcryptjs";
import NextAuth, { getServerSession, type NextAuthOptions } from "next-auth";
import Credentials from "next-auth/providers/credentials";
import { prisma } from "./prisma";

export const authOptions: NextAuthOptions = {
  session: { strategy: "jwt" },
  secret: process.env.AUTH_SECRET,
  providers: [
    Credentials({
      name: "credentials",
      credentials: {
        email: { label: "Email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(creds) {
        const email = creds?.email as string | undefined;
        const password = creds?.password as string | undefined;

        if (!email || !password) return null;

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) return null;

        const valid = await bcrypt.compare(password, user.password);
        if (!valid) return null;

        return { id: user.id, email: user.email, name: user.name ?? undefined };
      },
    }),
  ],
};

const handler = NextAuth(authOptions);

export const auth = () => getServerSession(authOptions);

export { handler as GET, handler as POST };
export { signIn, signOut } from "next-auth/react";
EOF

# 12) Store setup
cat > src/store/store.ts <<'EOF'
import { configureStore } from "@reduxjs/toolkit";
import counter from "./slices/counter.slice";
import { api } from "./services/api";

export const store = configureStore({
  reducer: { counter, [api.reducerPath]: api.reducer },
  middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(api.middleware),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
EOF

cat > src/store/hooks.ts <<'EOF'
import { TypedUseSelectorHook, useDispatch, useSelector } from "react-redux";
import type { RootState, AppDispatch } from "./store";

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
EOF

cat > src/store/services/api.ts <<'EOF'
import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

export const api = createApi({
  reducerPath: "api",
  baseQuery: fetchBaseQuery({ baseUrl: "/api" }),
  endpoints: (build) => ({
    ping: build.query<{ ok: boolean }, void>({
      query: () => "ping",
    }),
  }),
});

export const { usePingQuery } = api;
EOF

cat > src/store/slices/counter.slice.ts <<'EOF'
import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

type CounterState = { value: number };

const initialState: CounterState = { value: 0 };

const counterSlice = createSlice({
  name: "counter",
  initialState,
  reducers: {
    increment: (state) => {
      state.value += 1;
    },
    add: (state, action: PayloadAction<number>) => {
      state.value += action.payload;
    },
    reset: () => initialState,
  },
});

export const { increment, add, reset } = counterSlice.actions;
export default counterSlice.reducer;
EOF

# 13) Ensure no deprecated middleware is created for Next.js 16+; prefer proxy
if [ -f src/proxy.ts ]; then
  echo "src/proxy.ts exists; skipping creation of src/middleware.ts"
else
  # create a harmless proxy placeholder compatible with Next.js 16+
  cat > src/proxy.ts <<'EOF'
// Placeholder proxy for Next.js 16+. Do not create src/middleware.ts when proxy is present.
export default function proxy() {
  // no-op
  return;
}
EOF
  echo "Created src/proxy.ts placeholder (Next.js 16+)."
fi

echo "Dashboard scaffold updated. Run: pnpm dev → http://localhost:3000"
