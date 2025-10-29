"use client";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { increment } from "@/store/slices/counter.slice";
import { Button } from "@/components/ui/button";
import { usePingQuery } from "@/store/services/api";
import Link from "next/link";
export default function Page() {
  const v = useAppSelector((s) => s.counter.value);
  const d = useAppDispatch();
  const { data } = usePingQuery();
  return (
    <main className="p-8 space-y-4">
      <h1 className="text-2xl font-semibold">Next + Redux + RTKQ + shadcn + Auth</h1>
      <div className="space-x-3">
        <span>Count: {v}</span>
        <Button onClick={() => d(increment())}>Increment</Button>
      </div>
      <p>Ping: {data?.ok ? "ok" : "loading…"}</p>
      <div className="space-x-4">
        <Link href="/login">Login</Link>
        <Link href="/signup">Sign up</Link>
        <Link href="/dashboard">Dashboard</Link>
      </div>
    </main>
  );
}
