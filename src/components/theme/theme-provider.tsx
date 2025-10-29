"use client";
import * as React from "react";
import { useEffect } from "react";
import { ThemeProvider as NextThemesProvider, useTheme } from "next-themes";
import { themeClassMap, themeOptions } from "./theme-config";

const themeKeys = themeOptions.map((option) => option.value);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return (
    <NextThemesProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      themes={themeKeys}
      value={themeClassMap}
    >
      <ThemeClassWatcher />
      {children}
    </NextThemesProvider>
  );
}

function ThemeClassWatcher() {
  const { theme, resolvedTheme } = useTheme();
  useEffect(() => {
    if (typeof document === "undefined") return;
    const root = document.documentElement;
    const activeTheme = theme === "system" ? resolvedTheme : theme;
    const isDark = activeTheme ? activeTheme === "dark" || activeTheme.endsWith("-dark") : false;
    if (isDark) {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
  }, [theme, resolvedTheme]);
  return null;
}
