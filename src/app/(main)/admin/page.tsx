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
