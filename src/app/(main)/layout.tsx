import type { ReactNode } from "react";
import TopNav from "@/components/shell/TopNav";
import Sidebar from "@/components/shell/Sidebar";
import { TailwindForce } from "@/components/ui/tailwind-force";

export default function MainLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh bg-background">
      <TopNav />
      <div className="mx-auto flex w-full max-w-7xl gap-6 px-4 py-6">
        <Sidebar />
        <main className="flex-1 space-y-6">{children}</main>
        <TailwindForce />
      </div>
    </div>
  );
}
