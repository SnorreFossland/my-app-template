import type { Metadata } from "next";
import "./globals.css";
import Providers from "./providers";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import { Toaster } from "sonner";
import { TailwindForce } from "@/components/ui/tailwind-force";

export const metadata: Metadata = { title: "App", description: "Scaffold" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-background text-foreground antialiased">
        <Providers>
          <TailwindForce />
          <Toaster richColors />
          <div className="p-4 flex justify-end"><ThemeToggle /></div>
          {children}
        </Providers>
      </body>
    </html>
  );
}
