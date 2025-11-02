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
