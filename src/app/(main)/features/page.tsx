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
