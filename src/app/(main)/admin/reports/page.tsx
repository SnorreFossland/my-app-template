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
