"use client";
import Link from "next/link";

import { ThemeToggle } from "@/components/theme/theme-toggle";

export default function DashboardHeader() {
  return (
    <header className="border-b bg-card">
      <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-4 py-3">
        <div className="flex items-center gap-3">
          <Link href="/" aria-label="Back to home" className="-m-2 rounded p-2 hover:bg-muted/50">
            {/* simple hamburger/back icon */}
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="h-5 w-5"
            >
              <path d="M3 12h18" />
              <path d="M3 6h18" />
              <path d="M3 18h18" />
            </svg>
          </Link>
          <h1 className="text-lg font-semibold">Dashboard</h1>
        </div>
        <div className="ml-2 flex items-center">
          <ThemeToggle />
        </div>
      </div>
    </header>
  );
}
