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
