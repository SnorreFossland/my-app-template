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
