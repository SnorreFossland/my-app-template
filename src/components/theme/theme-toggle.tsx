"use client";
import { type ReactElement } from "react";
import { useTheme } from "next-themes";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Sun, Moon } from "lucide-react";
import { themeOptions } from "./theme-config";

export function ThemeToggle() {
  const { setTheme, theme, resolvedTheme } = useTheme();
  const currentThemeValue = theme === undefined ? resolvedTheme ?? "system" : theme;
  const menuItems: ReactElement[] = [];
  let previousGroup: string | undefined;

  themeOptions.forEach((option) => {
    if (option.group) {
      if (option.group !== previousGroup) {
        if (menuItems.length > 0) {
          menuItems.push(<DropdownMenuSeparator key={`sep-${option.group}`} />);
        }
        menuItems.push(<DropdownMenuLabel key={`label-${option.group}`}>{option.group}</DropdownMenuLabel>);
        previousGroup = option.group;
      }
    } else if (menuItems.length > 0) {
      menuItems.push(<DropdownMenuSeparator key={`sep-${option.value}`} />);
      previousGroup = undefined;
    }

    menuItems.push(
      <DropdownMenuRadioItem key={option.value} value={option.value}>
        {option.label}
      </DropdownMenuRadioItem>,
    );
  });

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" aria-label="Toggle theme">
          <Sun className="h-5 w-5 dark:hidden" /><Moon className="h-5 w-5 hidden dark:block" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuRadioGroup value={currentThemeValue} onValueChange={setTheme}>
          {menuItems}
        </DropdownMenuRadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
