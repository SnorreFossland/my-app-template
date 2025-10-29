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
