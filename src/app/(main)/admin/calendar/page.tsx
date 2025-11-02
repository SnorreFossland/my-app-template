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
