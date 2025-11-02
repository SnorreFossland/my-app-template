#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/add-admin-pages.sh [target-dir]
# Writes the opinionated admin experience (layout, dashboard, and sub-pages).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_next_script() {
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    return 0
  fi

  local prompt="$1"
  shift || return 0

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  local -a orig_cmd=("$@")
  local -a cmd=("${orig_cmd[@]}")

  if [ -f "${cmd[0]}" ] && [ ! -x "${cmd[0]}" ]; then
    if [[ "${cmd[0]}" == *.sh ]]; then
      cmd=(bash "${cmd[@]}")
    fi
  fi

  local display_cmd="${cmd[*]}"

  printf "%s [y/N] " "$prompt"
  read -r reply || return 0
  if [[ "$reply" =~ ^[Yy](es)?$ ]]; then
    echo "Running ${display_cmd} ..."
    "${cmd[@]}"
  else
    echo "Skipping ${display_cmd}."
  fi
}

TARGET_DIR_INPUT="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR_INPUT" && pwd)"
cd "$TARGET_DIR"

start_prisma_studio() {
  local port="${PRISMA_STUDIO_PORT:-5555}"

  if command -v lsof >/dev/null 2>&1 && lsof -ti ":${port}" >/dev/null 2>&1; then
    echo "Prisma Studio already running on port ${port}, skipping startup."
    return 0
  fi

  local -a cmd
  if command -v pnpm >/dev/null 2>&1; then
    cmd=(pnpm exec prisma studio)
  elif command -v npx >/dev/null 2>&1; then
    cmd=(npx prisma studio)
  else
    echo "Skipping Prisma Studio startup: neither pnpm nor npx is available."
    return 0
  fi

  cmd+=(--browser none --port "${port}")

  echo "Starting Prisma Studio on http://localhost:${port} ..."
  if command -v nohup >/dev/null 2>&1; then
    nohup "${cmd[@]}" >/dev/null 2>&1 &
  else
    "${cmd[@]}" >/dev/null 2>&1 &
  fi

  local pid=$!
  if kill -0 "${pid}" >/dev/null 2>&1; then
    echo "Prisma Studio running in background (PID ${pid})."
  else
    echo "Unable to confirm Prisma Studio startup. Check logs if needed."
  fi
}

echo "Scaffolding admin workspace in: $(pwd)"

# Ensure base directories exist (parentheses require quoting to avoid globbing)
mkdir -p "src/app/(main)/admin"
mkdir -p "src/app/(main)/admin/reports"
mkdir -p "src/app/(main)/admin/settings"
mkdir -p "src/app/(main)/admin/review"
mkdir -p "src/app/(main)/admin/calendar"

# Admin navigation component
cat > "src/app/(main)/admin/AdminNav.tsx" <<'EOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { cn } from "@/lib/utils";

const navLinks = [
  { href: "/admin", label: "Overview" },
  { href: "/admin/reports", label: "Reports" },
  { href: "/admin/settings", label: "Roles" },
  { href: "/admin/review", label: "Review Queue" },
  { href: "/admin/calendar", label: "Calendar" },
  { href: "http://localhost:5555", label: "Prisma Studio", external: true },
] as const;

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav aria-label="Admin navigation">
      <ul className="flex flex-wrap gap-2">
        {navLinks.map((link) => {
          const isExternal = Boolean(link.external);
          const isActive =
            !isExternal && (pathname === link.href || (link.href !== "/admin" && pathname.startsWith(`${link.href}/`)));

          return (
            <li key={link.href}>
              {isExternal ? (
                <a
                  href={link.href}
                  target="_blank"
                  rel="noreferrer"
                  className={cn(
                    "inline-flex items-center rounded-full border border-slate-700/70 px-3 py-1.5 text-sm font-medium transition",
                    "text-slate-300 hover:border-slate-600 hover:bg-slate-800/70 hover:text-slate-100"
                  )}
                >
                  {link.label}
                </a>
              ) : (
                <Link
                  href={link.href}
                  className={cn(
                    "inline-flex items-center rounded-full border border-transparent px-3 py-1.5 text-sm font-medium transition",
                    "text-slate-300 hover:border-slate-700 hover:bg-slate-800/70 hover:text-slate-100",
                    isActive && "border-slate-700 bg-slate-800/80 text-slate-50 shadow-inner"
                  )}
                >
                  {link.label}
                </Link>
              )}
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
EOF

# Admin layout (dark panel wrapper + nav)
cat > "src/app/(main)/admin/layout.tsx" <<'EOF'
import type { ReactNode } from "react";

import { AdminNav } from "./AdminNav";

export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-800 bg-slate-950 text-slate-100 shadow-2xl">
      <header className="flex flex-col gap-4 border-b border-slate-800 bg-slate-900/80 px-6 py-5 backdrop-blur">
        <p className="text-xs uppercase tracking-[0.35em] text-slate-400">Control surface</p>
        <h2 className="text-2xl font-semibold">Admin Area</h2>
        <p className="text-sm text-slate-400">
          A focused workspace for operators. Everything inside this panel uses a high-contrast palette to reduce visual
          noise during incident response.
        </p>
        <AdminNav />
      </header>
      <div className="px-6 py-8">{children}</div>
    </section>
  );
}
EOF

# Admin overview (server component with Prisma-backed roster + dark cards)
cat > "src/app/(main)/admin/page.tsx" <<'EOF'
import Link from "next/link";

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { prisma } from "@/auth/prisma";

const panelClass = "border-slate-800 bg-slate-900/60 shadow-xl";

const metricCards = [
  { title: "Active members", value: "1,248", change: "↑ 4.3% vs last week", tone: "positive" },
  { title: "Revenue (MRR)", value: "$24.5k", change: "↑ 6.1% month over month", tone: "positive" },
  { title: "Tickets open", value: "32", change: "8 awaiting reply", tone: "neutral" },
  { title: "Deploy success", value: "99.4%", change: "Last incident 12 days ago", tone: "neutral" },
] as const;

const reviewQueue = [
  { id: "USR-2048", name: "Asha Thomas", item: "Requesting billing admin role", submitted: "2 hours ago" },
  { id: "USR-1994", name: "Jordan Wu", item: "API key rotation pending", submitted: "6 hours ago" },
  { id: "ORG-311", name: "Northwind Labs", item: "Plan upgrade to Enterprise", submitted: "Yesterday" },
] as const;

const activityFeed = [
  { id: 1, title: "New feature flag enabled", detail: "Usage-based billing · rolled out to 35% of customers", time: "Just now" },
  { id: 2, title: "Database migration completed", detail: "Prisma migration `20241024123042_add_org_limits`", time: "39 minutes ago" },
  { id: 3, title: "Support SLA breach risk", detail: "Ticket #48217 waiting for reply for 55 minutes", time: "1 hour ago" },
  { id: 4, title: "Weekly usage summary sent", detail: "18 reports delivered to workspace owners", time: "Yesterday" },
] as const;

type AdminUser = {
  id: string;
  name: string | null;
  email: string;
  role: string;
  createdAt: string;
};

const fallbackUsers: AdminUser[] = [
  {
    id: "demo-01",
    name: "Aida Hassan",
    email: "aida@example.com",
    role: "admin",
    createdAt: new Date().toISOString(),
  },
  {
    id: "demo-02",
    name: "Noah Patel",
    email: "noah@example.com",
    role: "editor",
    createdAt: new Date().toISOString(),
  },
  {
    id: "demo-03",
    name: "Gabrielle Chen",
    email: "gabrielle@example.com",
    role: "viewer",
    createdAt: new Date().toISOString(),
  },
];

const changeToneClasses = {
  positive: "text-emerald-400",
  neutral: "text-slate-400",
  negative: "text-rose-400",
} as const;

async function getUsers(): Promise<AdminUser[]> {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: "desc" },
      take: 8,
    });

    return users.map((user) => ({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt.toISOString(),
    }));
  } catch (error) {
    console.error("Failed to load users for admin dashboard", error);
    return [];
  }
}

export default async function AdminPage() {
  const users = await getUsers();
  const userList = users.length > 0 ? users : fallbackUsers;
  const usingFallback = users.length === 0;

  const joinedFormatter = new Intl.DateTimeFormat("en", {
    dateStyle: "medium",
  });

  return (
    <main className="space-y-10 pb-10">
      <section className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div className="space-y-2">
          <h1 className="text-3xl font-semibold tracking-tight text-slate-50">Admin control center</h1>
          <p className="text-slate-400">
            Monitor platform health, unblock your teams, and keep operations moving. Everything you need to run the
            workspace lives here.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button asChild>
            <Link href="/admin/reports">Create report</Link>
          </Button>
          <Button
            variant="outline"
            className="border-slate-700 text-slate-200 hover:bg-slate-800/70"
            asChild
          >
            <Link href="/admin/settings">Manage roles</Link>
          </Button>
        </div>
      </section>

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {metricCards.map((metric) => (
          <Card key={metric.title} className={panelClass}>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-slate-300">{metric.title}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-semibold tracking-tight text-slate-50">{metric.value}</div>
              <p className={`mt-2 text-sm ${changeToneClasses[metric.tone]}`}>{metric.change}</p>
            </CardContent>
          </Card>
        ))}
      </section>

      <section className="grid gap-4 lg:grid-cols-[2fr,1fr]">
        <Card className={panelClass}>
          <CardHeader>
            <CardTitle>Operational highlights</CardTitle>
            <CardDescription className="text-slate-400">
              Latest changes and signals from across the platform.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {activityFeed.map((item, index) => (
              <div key={item.id}>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-medium">{item.title}</p>
                    <p className="text-sm text-slate-400">{item.detail}</p>
                  </div>
                  <span className="text-xs text-slate-500 whitespace-nowrap">{item.time}</span>
                </div>
                {index < activityFeed.length - 1 && <Separator className="my-4 border-slate-800" />}
              </div>
            ))}
          </CardContent>
        </Card>

        <Card className={panelClass}>
          <CardHeader>
            <CardTitle>Requires review</CardTitle>
            <CardDescription className="text-slate-400">
              Approve or delegate the latest workspace requests.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {reviewQueue.map((item) => (
              <div key={item.id} className="rounded-lg border border-dashed border-slate-700 bg-slate-900/50 p-4">
                <p className="text-sm font-semibold">{item.name}</p>
                <p className="text-sm text-slate-400">{item.item}</p>
                <p className="mt-1 text-xs text-slate-500">Submitted {item.submitted}</p>
              </div>
            ))}
          </CardContent>
          <CardFooter className="flex justify-end">
            <Button variant="ghost" className="px-2 text-sm text-slate-200 hover:bg-slate-800/70" asChild>
              <Link href="/admin/review">View queue</Link>
            </Button>
          </CardFooter>
        </Card>
      </section>

      <Card className={panelClass}>
        <CardHeader>
          <CardTitle>User roster</CardTitle>
          <CardDescription className="text-slate-400">
            {usingFallback
              ? "No users found yet, showing sample data until someone signs up."
              : "Latest members to join the workspace."}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-2">
          <div className="hidden grid-cols-[1.5fr_1.2fr_auto_auto_auto] items-center gap-4 px-2 pb-2 text-xs uppercase tracking-wide text-slate-500 sm:grid">
            <span>Name</span>
            <span>Email</span>
            <span>Role</span>
            <span>Joined</span>
            <span className="text-right">Actions</span>
          </div>
          <div className="divide-y divide-slate-800 rounded-xl border border-slate-800 bg-slate-950/50">
            {userList.map((user) => (
              <div
                key={user.id}
                className="grid gap-3 px-4 py-4 text-sm sm:grid-cols-[1.5fr_1.2fr_auto_auto_auto] sm:items-center"
              >
                <div>
                  <p className="font-medium">{user.name ?? "Unnamed user"}</p>
                  <p className="text-xs text-slate-500 sm:hidden">{user.email}</p>
                </div>
                <p className="hidden text-sm text-slate-400 sm:block">{user.email}</p>
                <span className="w-fit rounded-full border border-slate-700 px-2 py-1 text-xs uppercase tracking-wide text-slate-300">
                  {user.role}
                </span>
                <span className="text-xs text-slate-500">
                  {joinedFormatter.format(new Date(user.createdAt))}
                </span>
                <div className="sm:justify-self-end">
                  <Button
                    variant="outline"
                    size="sm"
                    className="mt-3 border-slate-700 text-slate-200 hover:bg-slate-800/70 sm:mt-0"
                    asChild
                  >
                    <Link href={`/admin/users/${user.id}`}>Manage</Link>
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card className={panelClass}>
        <CardHeader>
          <CardTitle>Upcoming schedule</CardTitle>
          <CardDescription className="text-slate-400">
            Track the key work that keeps the workspace running smoothly.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          <div className="space-y-2 rounded-lg border border-slate-800 bg-slate-900/60 p-4">
            <p className="text-sm font-semibold">Security audit</p>
            <p className="text-sm text-slate-400">Finalize SOC2 evidence package and lock scope.</p>
            <p className="text-xs text-slate-500">Due Friday · Lead: Priya</p>
          </div>
          <div className="space-y-2 rounded-lg border border-slate-800 bg-slate-900/60 p-4">
            <p className="text-sm font-semibold">Billing migration</p>
            <p className="text-sm text-slate-400">Migrate legacy Stripe customers into usage plans.</p>
            <p className="text-xs text-slate-500">Due in 4 days · Lead: Mateo</p>
          </div>
          <div className="space-y-2 rounded-lg border border-slate-800 bg-slate-900/60 p-4">
            <p className="text-sm font-semibold">Talent onboarding</p>
            <p className="text-sm text-slate-400">Provision SSO + group policies for the new data team.</p>
            <p className="text-xs text-slate-500">Due next week · Lead: Lila</p>
          </div>
        </CardContent>
        <CardFooter className="justify-end">
          <Button
            variant="outline"
            size="sm"
            className="border-slate-700 text-slate-200 hover:bg-slate-800/70"
            asChild
          >
            <Link href="/admin/calendar">Open calendar</Link>
          </Button>
        </CardFooter>
      </Card>
    </main>
  );
}
EOF

# Reports page
cat > "src/app/(main)/admin/reports/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const savedReports = [
  { id: "rpt_01", name: "Weekly health summary", updated: "Updated 2 hours ago" },
  { id: "rpt_02", name: "Finance & billing drill-down", updated: "Updated yesterday" },
  { id: "rpt_03", name: "Customer adoption cohort", updated: "Updated 4 days ago" },
] as const;

export default function AdminReportsPage() {
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-semibold tracking-tight">Report builder</h1>
        <p className="text-muted-foreground">
          Assemble quick snapshots for stakeholders or dig into advanced metrics with filters and segments.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Quick export</CardTitle>
          <CardDescription>Choose the timeframe and destination for a one-off export.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div className="space-y-2">
            <Label htmlFor="range">Date range</Label>
            <Input id="range" placeholder="Last 7 days" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="segment">Segment</Label>
            <Input id="segment" placeholder="All customers" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="destination">Destination email</Label>
            <Input id="destination" placeholder="ops-team@example.com" type="email" />
          </div>
          <div className="sm:col-span-2 lg:col-span-3 flex justify-end">
            <Button>Generate report</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Saved reports</CardTitle>
          <CardDescription>Re-run an existing template or iteratively improve it.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {savedReports.map((report) => (
            <div
              key={report.id}
              className="flex flex-col gap-2 rounded-lg border border-border/60 bg-muted/30 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
            >
              <div>
                <p className="font-medium">{report.name}</p>
                <p className="text-sm text-muted-foreground">{report.updated}</p>
              </div>
              <div className="flex gap-2">
                <Button variant="ghost" size="sm">
                  Edit
                </Button>
                <Button size="sm">Run</Button>
              </div>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
EOF

# Settings page
cat > "src/app/(main)/admin/settings/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";

const roleDefinitions = [
  { name: "Owner", detail: "Full access, billing, and security controls." },
  { name: "Admin", detail: "Manage users, integrations, and workspace policy." },
  { name: "Contributor", detail: "Access to product areas with write permission." },
  { name: "Viewer", detail: "Read-only visibility across enabled modules." },
] as const;

export default function AdminSettingsPage() {
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-semibold tracking-tight">Role management</h1>
        <p className="text-muted-foreground">
          Control who can view, edit, and deploy changes. Assign roles that align with your team&apos;s responsibilities.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Invite teammate</CardTitle>
          <CardDescription>Add a new member and choose the right role.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div className="space-y-2">
            <Label htmlFor="name">Full name</Label>
            <Input id="name" placeholder="Ada Lovelace" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="email">Email address</Label>
            <Input id="email" placeholder="ada@example.com" type="email" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="role">Role</Label>
            <Input id="role" placeholder="Select a role" />
          </div>
          <div className="sm:col-span-2 lg:col-span-3 flex justify-end">
            <Button>Send invite</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Role catalogue</CardTitle>
          <CardDescription>Reference each access level and its primary capabilities.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {roleDefinitions.map((role, index) => (
            <div key={role.name}>
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="font-medium">{role.name}</p>
                  <p className="text-sm text-muted-foreground">{role.detail}</p>
                </div>
                <Button variant="ghost" size="sm">
                  Edit
                </Button>
              </div>
              {index < roleDefinitions.length - 1 && <Separator className="my-4" />}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
EOF

# Review queue page
cat > "src/app/(main)/admin/review/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";

const reviewItems = [
  {
    id: "SEC-188",
    title: "Reset MFA for Shelby Flores",
    detail: "Requested by workspace admin. Verify account before approving.",
    age: "Queued 18 minutes",
  },
  {
    id: "APP-812",
    title: "Approve integration: Segment",
    detail: "Requires admin sign-off because permission scope includes user PII.",
    age: "Queued 43 minutes",
  },
  {
    id: "BILL-097",
    title: "Invoice dispute · Plan Enterprise",
    detail: "Customer flagged an overage charge. Attach audit log before responding.",
    age: "Queued 1 hour",
  },
] as const;

export default function AdminReviewQueuePage() {
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-semibold tracking-tight">Review queue</h1>
        <p className="text-muted-foreground">
          Resolve high-signal requests that need administrative approval. Prioritize items with security or billing
          impact first.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Pending approvals</CardTitle>
          <CardDescription>Each action requires confirmation before it can complete.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {reviewItems.map((item, index) => (
            <div key={item.id}>
              <div className="flex flex-col gap-3 rounded-lg border border-dashed border-border/70 bg-muted/30 p-4 sm:flex-row sm:items-start sm:justify-between">
                <div className="space-y-1">
                  <p className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">{item.id}</p>
                  <p className="text-base font-medium">{item.title}</p>
                  <p className="text-sm text-muted-foreground">{item.detail}</p>
                </div>
                <div className="flex flex-col gap-2 sm:items-end">
                  <span className="text-xs text-muted-foreground">{item.age}</span>
                  <div className="flex gap-2">
                    <Button size="sm" variant="ghost">
                      Delegate
                    </Button>
                    <Button size="sm">Approve</Button>
                  </div>
                </div>
              </div>
              {index < reviewItems.length - 1 && <Separator className="my-4" />}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
EOF

# Calendar page
cat > "src/app/(main)/admin/calendar/page.tsx" <<'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";

const upcomingEvents = [
  {
    title: "Incident response tabletop",
    description: "Runbook validation with SRE + Support.",
    schedule: "Monday · 10:00 AM – 11:30 AM",
    location: "Zoom · invite shared",
  },
  {
    title: "Quarterly business review",
    description: "Executive sync with Northwind Labs account team.",
    schedule: "Wednesday · 1:00 PM – 2:00 PM",
    location: "Conference Room 3A",
  },
  {
    title: "Product roadmap checkpoint",
    description: "Align roadmap vs. usage metrics ahead of launch.",
    schedule: "Thursday · 4:00 PM – 5:00 PM",
    location: "Notion doc · async",
  },
] as const;

export default function AdminCalendarPage() {
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-semibold tracking-tight">Operations calendar</h1>
        <p className="text-muted-foreground">
          Keep on top of the rituals, reviews, and readiness checkpoints that keep the workspace healthy.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>This week</CardTitle>
          <CardDescription>High-impact meetings and milestones.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {upcomingEvents.map((event, index) => (
            <div key={event.title}>
              <div className="space-y-1 rounded-lg border border-border/60 bg-muted/30 p-4">
                <p className="font-medium">{event.title}</p>
                <p className="text-sm text-muted-foreground">{event.description}</p>
                <p className="text-sm text-muted-foreground">{event.schedule}</p>
                <p className="text-xs text-muted-foreground">{event.location}</p>
                <div className="pt-3">
                  <Button size="sm" variant="outline">
                    Add to calendar
                  </Button>
                </div>
              </div>
              {index < upcomingEvents.length - 1 && <Separator className="my-4" />}
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Automations</CardTitle>
          <CardDescription>Send reminders or auto-assign owners ahead of events.</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          <Button size="sm" variant="ghost">
            Notify owners 24 hours before
          </Button>
          <Button size="sm" variant="ghost">
            Flag conflicting invites
          </Button>
          <Button size="sm" variant="ghost">
            Share digest with stakeholders
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
EOF

echo "Admin scaffold created."
echo "Next: pnpm run dev  # then visit http://localhost:3000/admin"
start_prisma_studio || true
prompt_next_script "Create a test user now?" node "$SCRIPT_DIR/create-test-user.js"
chmod +x "$0" 2>/dev/null || true
