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
