export type ThemeOption = {
  value: string;
  label: string;
  className?: string;
  group?: string;
};

export const themeOptions: ThemeOption[] = [
  { value: "light", label: "Default Light", className: "light", group: "Default" },
  { value: "dark", label: "Default Dark", className: "dark", group: "Default" },
  { value: "forest", label: "Forest Light", className: "theme-forest", group: "Forest" },
  { value: "forest-dark", label: "Forest Dark", className: "theme-forest-dark", group: "Forest" },
  { value: "ocean", label: "Ocean Light", className: "theme-ocean", group: "Ocean" },
  { value: "ocean-dark", label: "Ocean Dark", className: "theme-ocean-dark", group: "Ocean" },
  { value: "sunset", label: "Sunset Light", className: "theme-sunset", group: "Sunset" },
  { value: "sunset-dark", label: "Sunset Dark", className: "theme-sunset-dark", group: "Sunset" },
  { value: "system", label: "System" },
];

export const themeClassMap = themeOptions.reduce<Record<string, string>>((acc, option) => {
  if (option.className) {
    acc[option.value] = option.className;
  }
  return acc;
}, {});
