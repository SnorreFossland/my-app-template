import type { ReactNode } from "react";

import { AdminNav } from "./AdminNav";

export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-800 bg-slate-950 text-slate-100 shadow-2xl">
      <header className="flex flex-col gap-4 border-b border-slate-800 bg-slate-900/80 px-6 py-5 backdrop-blur">
        <p className="text-xs uppercase tracking-[0.35em] text-slate-400">Control surface</p>
        <h2 className="text-2xl font-semibold">Admin Area</h2>
        <p className="text-sm text-slate-400">
          A focused workspace for operators. Everything inside this panel uses a high-contrast palette to reduce visual
          noise during incident response.
        </p>
        <AdminNav />
      </header>
      <div className="px-6 py-8">{children}</div>
    </section>
  );
}
