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
