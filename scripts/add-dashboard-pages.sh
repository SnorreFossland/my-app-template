#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_next_script() {
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    return 0
  fi

  local prompt="$1"
  shift || return 0

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  local -a orig_cmd=("$@")
  local -a cmd=("${orig_cmd[@]}")

  if [ -f "${cmd[0]}" ] && [ ! -x "${cmd[0]}" ]; then
    if [[ "${cmd[0]}" == *.sh ]]; then
      cmd=(bash "${cmd[@]}")
    fi
  fi

  local display_cmd="${cmd[*]}"

  printf "%s [y/N] " "$prompt"
  read -r reply || return 0
  if [[ "$reply" =~ ^[Yy](es)?$ ]]; then
    echo "Running ${display_cmd} ..."
    "${cmd[@]}"
  else
    echo "Skipping ${display_cmd}."
  fi
}

# Usage: ./add-dashboard-pages.sh [target-dir]
# If no directory is provided, the script runs in the current working directory.
TARGET_DIR_INPUT="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR_INPUT" && pwd)"
cd "$TARGET_DIR"

echo "Scaffolding dashboard route in: $(pwd)"

# Ensure directories exist
mkdir -p src/components/dashboard
mkdir -p src/app/dashboard
mkdir -p src/app/dashboard/three-panel


# Three-panel wrapper (dashboard) with pointer support
cat > src/components/dashboard/ThreePanels.tsx <<'EOF'
"use client";
import React, { useRef, useState } from "react";
import Panel from "@/components/dashboard/Panel";

function Gutter({ onPointerDown }: { onPointerDown: (e: React.PointerEvent) => void }) {
  return (
    <div
      onPointerDown={onPointerDown}
      className="w-3 md:w-3 h-full z-20 flex items-center justify-center"
      style={{ cursor: "col-resize" }}
      aria-hidden
    >
      {/* visible grip to make gutter obvious and easier to hit */}
      <div className="h-8 w-0.5 rounded bg-border/60 dark:bg-border/40" />
    </div>
  );
}

export default function ThreePanels() {
  // percentages for three columns; sum should be ~100
  const [sizes, setSizes] = useState([33.33, 33.33, 33.34]);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const dragState = useRef<{ index: number; startX: number; startSizes: number[] } | null>(null);

  // Use Pointer events so dragging works on mouse and touch devices
  const startDrag = (index: number) => (e: React.PointerEvent) => {
    e.preventDefault();
    const target = e.target as Element;
    try {
      // @ts-ignore - Pointer capture might not be present on all elements but it's safe to try
      (target as HTMLElement).setPointerCapture?.(e.pointerId);
    } catch {
    }
    dragState.current = { index, startX: e.clientX, startSizes: [...sizes] };
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", endDrag);
  };

  const onPointerMove = (ev: PointerEvent) => {
    if (!dragState.current || !containerRef.current) return;
    const { index, startX, startSizes } = dragState.current;
    const deltaX = ev.clientX - startX;
    const containerWidth = containerRef.current.getBoundingClientRect().width;
    const deltaPct = (deltaX / containerWidth) * 100;
    const newSizes = [...startSizes];
    // adjust the two panels around the gutter: left (index) and right (index+1)
    newSizes[index] = Math.max(5, Math.min(90, startSizes[index] + deltaPct));
    newSizes[index + 1] = Math.max(5, Math.min(90, startSizes[index + 1] - deltaPct));
    setSizes(newSizes);
  };

  const endDrag = (ev?: PointerEvent) => {
    dragState.current = null;
    window.removeEventListener("pointermove", onPointerMove);
    window.removeEventListener("pointerup", endDrag);
  };

  // Give the container an explicit height so panels render reasonably and resizable area is visible
  return (
    <div ref={containerRef} className="flex gap-0 items-stretch h-[calc(100vh-8rem)]">
      {/* use flex-grow proportions so gutters (fixed px) don't cause overflow */}
      <div style={{ flexBasis: `${sizes[0]}%`, flexGrow: 0, flexShrink: 1 }}>
        <Panel title="Overview">
          <p className="text-sm text-muted-foreground">Quick metrics and status.</p>
        </Panel>
      </div>

      <Gutter onPointerDown={startDrag(0)} />

      <div style={{ flexBasis: `${sizes[1]}%`, flexGrow: 0, flexShrink: 1 }}>
        <Panel title="Activity">
          <p className="text-sm text-muted-foreground">Recent activity and logs.</p>
        </Panel>
      </div>

      <Gutter onPointerDown={startDrag(1)} />

      <div style={{ flexBasis: `${sizes[2]}%`, flexGrow: 0, flexShrink: 1 }}>
        <Panel title="Insights">
          <p className="text-sm text-muted-foreground">Charts and analysis highlights.</p>
        </Panel>
      </div>
    </div>
  );
}
EOF

# Dashboard header
cat > src/components/shell/DashboardHeader.tsx <<'EOF'
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
EOF

# Dashboard layout (App Router)
cat > src/app/dashboard/layout.tsx <<'EOF'
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
EOF

# Dashboard UI page placed under /dashboard/three-panel so it doesn't overwrite an auth-gated /dashboard
cat > src/app/dashboard/page.tsx <<'EOF'
import ThreePanels from "@/components/dashboard/ThreePanels";

export default function ThreePanelPage() {
  return (
    <div className=" p-1">
      <h3 className="text-2xl font-semibold"></h3>
      <div className="rounded-lg border bg-card p-1">
        <ThreePanels />
      </div>
    </div>
  );
}
EOF

# Add dashboard link to sidebar if missing
NAV_FILE="src/components/shell/Sidebar.tsx"
if [ -f "$NAV_FILE" ]; then
  if ! grep -q 'href: "/dashboard"' "$NAV_FILE"; then
    awk '/export const sidebarLinks = \[/{print; print "  { href: \"/dashboard\", label: \"Dashboard\" },"; next}1' \
      "$NAV_FILE" > "$NAV_FILE.tmp" && mv "$NAV_FILE.tmp" "$NAV_FILE"
    echo 'Added /dashboard link (labelled Dashboard) to Sidebar.tsx'
  fi
fi

echo "Dashboard scaffold created."
echo "Next: pnpm dev  # visit http://localhost:3000/dashboard"
prompt_next_script "Run the admin scaffold script now?" "$SCRIPT_DIR/add-admin-pages.sh" "$TARGET_DIR"
chmod +x "$0" 2>/dev/null || true
