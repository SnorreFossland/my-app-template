"use client";

import { useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

const MOCK_DATA = {
  weekly: [120, 180, 210, 260, 300, 340, 420],
  monthly: [820, 760, 880, 940, 1010, 980, 1105, 1180, 1250, 1330, 1405, 1500],
};

function formatSeries(series: number[]) {
  const max = Math.max(...series);
  return series.map((value) => Math.round((value / max) * 100));
}

export default function AnalyticsPage() {
  const [range, setRange] = useState<"weekly" | "monthly">("weekly");
  const points = useMemo(() => formatSeries(MOCK_DATA[range]), [range]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Analytics</CardTitle>
          <CardDescription>Simple engagement trends using mocked data.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center gap-2">
            <Button size="sm" variant={range === "weekly" ? "default" : "outline"} onClick={() => setRange("weekly")}>
              Weekly
            </Button>
            <Button size="sm" variant={range === "monthly" ? "default" : "outline"} onClick={() => setRange("monthly")}>
              Monthly
            </Button>
          </div>

          <div className="grid gap-2 text-xs text-muted-foreground md:grid-cols-12">
            {points.map((value, idx) => (
              <div key={idx} className="flex flex-col items-center justify-end gap-2 rounded border bg-muted/20 p-2">
                <div
                  className="w-full rounded bg-primary/70"
                  style={{ height: `${Math.max(value, 10)}%`, minHeight: "2.5rem" }}
                />
                <span className="font-medium text-foreground">{MOCK_DATA[range][idx]}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
