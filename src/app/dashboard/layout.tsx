import type { ReactNode } from "react";
import DashboardHeader from "@/components/shell/DashboardHeader";

export default function ThreePanelLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh bg-background">
      <DashboardHeader />
      <div className="mx-auto flex w-full max-w-7xl gap-6 px-4 py-6">
        <main className="flex-1 space-y-6">{children}</main>
      </div>
    </div>
  );
}
