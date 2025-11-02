"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { cn } from "@/lib/utils";

const navLinks = [
  { href: "/admin", label: "Overview" },
  { href: "/admin/reports", label: "Reports" },
  { href: "/admin/settings", label: "Roles" },
  { href: "/admin/review", label: "Review Queue" },
  { href: "/admin/calendar", label: "Calendar" },
  { href: "http://localhost:5555", label: "Prisma Studio", external: true },
] as const;

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav aria-label="Admin navigation">
      <ul className="flex flex-wrap gap-2">
        {navLinks.map((link) => {
          const isExternal = Boolean(link.external);
          const isActive =
            !isExternal && (pathname === link.href || (link.href !== "/admin" && pathname.startsWith(`${link.href}/`)));

          return (
            <li key={link.href}>
              {isExternal ? (
                <a
                  href={link.href}
                  target="_blank"
                  rel="noreferrer"
                  className={cn(
                    "inline-flex items-center rounded-full border border-slate-700/70 px-3 py-1.5 text-sm font-medium transition",
                    "text-slate-300 hover:border-slate-600 hover:bg-slate-800/70 hover:text-slate-100"
                  )}
                >
                  {link.label}
                </a>
              ) : (
                <Link
                  href={link.href}
                  className={cn(
                    "inline-flex items-center rounded-full border border-transparent px-3 py-1.5 text-sm font-medium transition",
                    "text-slate-300 hover:border-slate-700 hover:bg-slate-800/70 hover:text-slate-100",
                    isActive && "border-slate-700 bg-slate-800/80 text-slate-50 shadow-inner"
                  )}
                >
                  {link.label}
                </Link>
              )}
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
