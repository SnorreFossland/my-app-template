
#!/usr/bin/env bash

set -euo pipefail
export PATH="$HOME/.nvm/versions/node/v20.9.0/bin:$PATH"
# ---- Node.js version check for Prisma ----
REQUIRED_NODE_VERSION="18.18.0"
NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//')
compare_versions() {
  [ "$1" = "$2" ] && return 0
  local IFS=.
  local i ver1=($1) ver2=($2)
  for ((i=0; i<${#ver1[@]}; i++)); do
    if ((10#${ver1[i]:-0} < 10#${ver2[i]:-0})); then return 1; fi
    if ((10#${ver1[i]:-0} > 10#${ver2[i]:-0})); then return 0; fi
  done
  return 0
}
if ! compare_versions "$NODE_VERSION" "$REQUIRED_NODE_VERSION"; then
  echo "Prisma requires Node.js >= $REQUIRED_NODE_VERSION. Current version: $NODE_VERSION"
  echo "Please upgrade Node.js and re-run this script."
  exit 1
fi

# ---- inputs ----
APP_NAME="${1:-my-app}"

# ---- helpers ----
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1"; exit 1; }; }

# ---- prereqs ----
need git; need node; command -v corepack >/dev/null 2>&1 || { echo "Missing corepack"; exit 1; }
corepack enable >/dev/null 2>&1 || true
corepack prepare pnpm@latest --activate
pnpm config set save-exact true

# ---- approve build scripts ----
if pnpm help approve-builds >/dev/null 2>&1; then
  echo "Approving build scripts for sharp and unrs-resolver..."
  pnpm approve-builds || true
fi

# uv for SpecKit
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi


# ---- scaffold app ----
if [ ! -d "$APP_NAME" ]; then
  pnpm create next-app@latest "$APP_NAME" \
    --ts --tailwind --eslint --app --src-dir --import-alias "@/*"
fi
cd "$APP_NAME"
[ -d .git ] || git init -q

# ---- tailwind setup (Tailwind v3 pinned) ----
node - <<'EOF'
const fs = require("fs");
const pkgPath = "package.json";
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
pkg.devDependencies = pkg.devDependencies || {};
pkg.devDependencies.tailwindcss = "3.4.17";
pkg.devDependencies.postcss = "8.4.49";
pkg.devDependencies.autoprefixer = "10.4.20";
delete pkg.devDependencies["@tailwindcss/postcss"];
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
EOF
cat > postcss.config.mjs <<'EOF'
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
EOF
cat > tailwind.config.ts <<'EOF'
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./src/app/**/*.{ts,tsx}",
    "./src/components/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-animate")],
};

export default config;
EOF

# ---- force correct NextAuth API route and handler (after cd) ----
mkdir -p src/app/api/auth/[...nextauth]
cat > src/app/api/auth/[...nextauth]/route.ts <<'EOF'
import NextAuth from "next-auth/next";
import { authOptions } from "@/auth/auth";

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
EOF
mkdir -p src/auth
cat > src/auth/auth.ts <<'EOF'
import Credentials from "next-auth/providers/credentials";
import { prisma } from "./prisma";
import bcrypt from "bcryptjs";
import type { Session, User } from "next-auth";
import type { JWT } from "next-auth/jwt";

export const authOptions = {
  providers: [
    Credentials({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(creds) {
        try {
          const email = creds?.email;
          const password = creds?.password;
          if (!email || !password) {
            console.error("Missing credentials");
            return null;
          }
          const user = await prisma.user.findUnique({ where: { email } });
          if (!user) {
            console.error("User not found");
            return null;
          }
          const ok = await bcrypt.compare(password, user.password);
          if (!ok) {
            console.error("Invalid password");
            return null;
          }
          return { id: user.id, email: user.email, name: user.name ?? undefined };
        } catch (err) {
          console.error("Authorize error:", err);
          return null;
        }
      }
    })
  ],
  session: { strategy: "jwt" as const },
  secret: process.env.AUTH_SECRET,
  callbacks: {
    async jwt({ token, user }: { token: JWT; user?: User }) {
      console.log('[NextAuth][jwt callback] token:', token, 'user:', user);
      if (user) {
        token.id = user.id;
        token.email = user.email;
        token.name = user.name;
      }
      return token;
    },
    async session({ session, token }: { session: Session; token: JWT }) {
      console.log('[NextAuth][session callback] session:', session, 'token:', token);
      if (token) {
        if (!session.user || typeof session.user !== "object") {
          session.user = {} as typeof session.user;
        }
        (session.user as any).id = (token as any).id;
        (session.user as any).email = (token as any).email;
        (session.user as any).name = (token as any).name;
      }
      return session;
    }
  }
};
EOF

[ -d .git ] || git init -q

# ---- deps ----
pnpm add @reduxjs/toolkit react-redux next-themes class-variance-authority tailwind-merge tailwindcss-animate lucide-react sonner
pnpm add next-auth @prisma/client bcryptjs zod react-hook-form @hookform/resolvers
pnpm add -D prisma

# ---- warn about next-auth peer dependency ----
if pnpm list next-auth | grep -q 'next@16'; then
  echo "Warning: next-auth expects Next.js ^12.2.5 || ^13 || ^14 || ^15, but found 16.0.0. You may encounter issues."
fi

# ---- tailwind setup (Tailwind v3 pinned) ----
node - <<'EOF'
const fs = require("fs");
const pkgPath = "package.json";
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
pkg.devDependencies = pkg.devDependencies || {};
pkg.devDependencies.tailwindcss = "3.4.17";
pkg.devDependencies.postcss = "8.4.49";
pkg.devDependencies.autoprefixer = "10.4.20";
delete pkg.devDependencies["@tailwindcss/postcss"];
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
EOF
cat > postcss.config.mjs <<'EOF'
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
EOF
cat > tailwind.config.ts <<'EOF'
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./src/app/**/*.{ts,tsx}",
    "./src/components/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-animate")],
};

export default config;
EOF


# ---- redux + rtkq ----
mkdir -p src/store/{slices,services}
cat > src/store/services/api.ts <<'EOF'
import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
export const api = createApi({
  reducerPath: "api",
  baseQuery: fetchBaseQuery({ baseUrl: "/api" }),
  endpoints: (b) => ({ ping: b.query<{ ok: boolean }, void>({ query: () => "ping" }) }),
});
export const { usePingQuery } = api;
EOF
cat > src/store/slices/counter.slice.ts <<'EOF'
import { createSlice, PayloadAction } from "@reduxjs/toolkit";
type State = { value: number }; const initialState: State = { value: 0 };
const slice = createSlice({
  name: "counter", initialState,
  reducers: { increment: s => { s.value += 1; }, add: (s,a:PayloadAction<number>)=>{s.value+=a.payload;}, reset:()=>initialState }
});
export const { increment, add, reset } = slice.actions; export default slice.reducer;
EOF
cat > src/store/store.ts <<'EOF'
import { configureStore } from "@reduxjs/toolkit";
import counter from "./slices/counter.slice";
import { api } from "./services/api";
export const store = configureStore({
  reducer: { counter, [api.reducerPath]: api.reducer },
  middleware: (gDM) => gDM().concat(api.middleware),
});
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
EOF
cat > src/store/hooks.ts <<'EOF'
import { TypedUseSelectorHook, useDispatch, useSelector } from "react-redux";
import type { RootState, AppDispatch } from "./store";
export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
EOF

# ---- shadcn (exclude deprecated toast) ----
pnpm dlx shadcn@latest init -y || true
pnpm dlx shadcn@latest add button card input label form dropdown-menu || true

# ---- theme provider + toggle ----
mkdir -p src/components/theme
cat > src/components/theme/theme-provider.tsx <<'EOF'
"use client";
import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return <NextThemesProvider attribute="class" defaultTheme="system" enableSystem>{children}</NextThemesProvider>;
}
EOF
cat > src/components/theme/theme-toggle.tsx <<'EOF'
"use client";
import { useTheme } from "next-themes";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Sun, Moon } from "lucide-react";
export function ThemeToggle() {
  const { setTheme } = useTheme();
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" aria-label="Toggle theme">
          <Sun className="h-5 w-5 dark:hidden" /><Moon className="h-5 w-5 hidden dark:block" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("light")}>Light</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dark")}>Dark</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("system")}>System</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
EOF

# ---- providers + layout (Sonner Toaster) ----
cat > src/app/providers.tsx <<'EOF'
"use client";
import { Provider } from "react-redux";
import { store } from "@/store/store";
import { ThemeProvider } from "@/components/theme/theme-provider";
import { SessionProvider } from "next-auth/react";
export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider>
      <ThemeProvider>
        <Provider store={store}>{children}</Provider>
      </ThemeProvider>
    </SessionProvider>
  );
}
EOF
# 5) UI helpers
cat > src/components/ui/tailwind-force.tsx <<'EOF'
export function TailwindForce() {
  return (
    <div
      className="hidden bg-background text-foreground border-border bg-primary text-primary-foreground bg-primary/90
      bg-secondary text-secondary-foreground bg-accent text-accent-foreground bg-destructive text-destructive-foreground
      bg-muted text-muted-foreground bg-popover text-popover-foreground bg-card text-card-foreground border-input
      hover:bg-accent hover:text-accent-foreground hover:bg-secondary/80 hover:bg-primary/90 shadow shadow-sm"
    >
      Tailwind force classes
    </div>
  );
}
EOF

cat > src/app/layout.tsx <<'EOF'
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
          {children}
        </Providers>
      </body>
    </html>
  );
}
EOF

# ---- demo page + api ----
mkdir -p src/app/api/ping
cat > src/app/api/ping/route.ts <<'EOF'
import { NextResponse } from "next/server";
export async function GET() { return NextResponse.json({ ok: true }); }
EOF
cat > src/app/page.tsx <<'EOF'
"use client";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { increment } from "@/store/slices/counter.slice";
import { Button } from "@/components/ui/button";
import { usePingQuery } from "@/store/services/api";
import Link from "next/link";
export default function Page() {
  const v = useAppSelector((s) => s.counter.value);
  const d = useAppDispatch();
  const { data } = usePingQuery();
  return (
    <main className="p-8 space-y-4">
      <h1 className="text-2xl font-semibold">Next + Redux + RTKQ + shadcn + Auth</h1>
      <div className="space-x-3">
        <span>Count: {v}</span>
        <Button onClick={() => d(increment())}>Increment</Button>
      </div>
      <p>Ping: {data?.ok ? "ok" : "loading…"}</p>
      <div className="space-x-4">
        <Link href="/login">Login</Link>
        <Link href="/signup">Sign up</Link>
        <Link href="/dashboard">Dashboard</Link>
      </div>
    </main>
  );
}
EOF
cat > src/app/globals.css <<'EOF'
@tailwind base; @tailwind components; @tailwind utilities;
:root { --font-sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial; }
html { color-scheme: light dark; }
EOF

# ---- prisma + sqlite (canonical multiline schema) ----
mkdir -p prisma
cat > prisma/schema.prisma <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF
# .env bootstrap
if [ ! -f .env ]; then
  cat > .env <<'EOF'
DATABASE_URL="file:./dev.db"
AUTH_SECRET="DkH1XUcQDX6RQjgqbo/xKszuXlAak0gTjZ770QA2+nE="
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="DkH1XUcQDX6RQjgqbo/xKszuXlAak0gTjZ770QA2+nE="
EOF
fi

# ---- next-auth (credentials) ----
mkdir -p src/auth 'src/app/api/auth/[...nextauth]'
cat > src/auth/prisma.ts <<'EOF'
import { PrismaClient } from "@prisma/client";
const g = global as unknown as { prisma?: PrismaClient };
export const prisma = g.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") g.prisma = prisma;
EOF
cat > src/auth/auth.ts <<'EOF'
import Credentials from "next-auth/providers/credentials";
import { prisma } from "./prisma";
import bcrypt from "bcryptjs";
import type { Session, User } from "next-auth";
import type { JWT } from "next-auth/jwt";

export const authOptions = {
  providers: [
    Credentials({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(creds) {
        try {
          const email = creds?.email;
          const password = creds?.password;
          if (!email || !password) {
            console.error("Missing credentials");
            return null;
          }
          const user = await prisma.user.findUnique({ where: { email } });
          if (!user) {
            console.error("User not found");
            return null;
          }
          const ok = await bcrypt.compare(password, user.password);
          if (!ok) {
            console.error("Invalid password");
            return null;
          }
          return { id: user.id, email: user.email, name: user.name ?? undefined };
        } catch (err) {
          console.error("Authorize error:", err);
          return null;
        }
      }
    })
  ],
  session: { strategy: "jwt" as const },
  secret: process.env.AUTH_SECRET,
  callbacks: {
    async jwt({ token, user }: { token: JWT; user?: User }) {
      console.log('[NextAuth][jwt callback] token:', token, 'user:', user);
      if (user) {
        token.id = user.id;
        token.email = user.email;
        token.name = user.name;
      }
      return token;
    },
    async session({ session, token }: { session: Session; token: JWT }) {
      console.log('[NextAuth][session callback] session:', session, 'token:', token);
      if (token) {
        if (!session.user || typeof session.user !== "object") {
          session.user = {} as typeof session.user;
        }
        (session.user as any).id = (token as any).id;
        (session.user as any).email = (token as any).email;
        (session.user as any).name = (token as any).name;
      }
      return session;
    }
  }
};
EOF
cat > 'src/app/api/auth/[...nextauth]/route.ts' <<'EOF'
import NextAuth from "next-auth/next";
import { authOptions } from "@/auth/auth";

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
EOF

# ---- signup api + pages + dashboard (quoted route group paths) ----
mkdir -p src/app/api/signup 'src/app/(auth)/login' 'src/app/(auth)/signup' src/app/dashboard
cat > src/app/api/signup/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { prisma } from "@/auth/prisma";
import bcrypt from "bcryptjs";
export async function POST(req: Request) {
  try {
    const { email, password, name } = await req.json().catch(() => ({}));
    if (!email || !password) {
      return NextResponse.json({ error: "Invalid" }, { status: 400 });
    }
    const exists = await prisma.user.findUnique({ where: { email } });
    if (exists) {
      return NextResponse.json({ error: "Exists" }, { status: 409 });
    }
    const hash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({ data: { email, password: hash, name } });
    return NextResponse.json({ id: user.id, email: user.email });
  } catch (err) {
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
EOF
cat > 'src/app/(auth)/login/page.tsx' <<'EOF'
"use client";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
const schema = z.object({ email: z.string().email(), password: z.string().min(6) });
export default function Login() {
  const r = useRouter();
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<{email:string;password:string}>({ resolver: zodResolver(schema) });
  return (
    <div className="p-8 max-w-md mx-auto">
      <Card className="p-6 space-y-4">
        <h2 className="text-xl font-semibold">Login</h2>
        <form
          onSubmit={handleSubmit(async (v) => {
            const resp = await signIn("credentials", { redirect: false, email: v.email, password: v.password });
            if (!resp || resp.error) alert("Invalid credentials");
            else r.push("/dashboard");
          })}
          className="space-y-3"
        >
          <Input type="email" placeholder="Email" autoComplete="username" {...register("email")} />
          {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          <Input type="password" placeholder="Password" autoComplete="current-password" {...register("password")} />
          {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          <Button type="submit" disabled={isSubmitting}>Sign in</Button>
        </form>
      </Card>
    </div>
  );
}
EOF
cat > 'src/app/(auth)/signup/page.tsx' <<'EOF'
"use client";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { useRouter } from "next/navigation";
const schema = z.object({ name: z.string().optional(), email: z.string().email(), password: z.string().min(6) });
export default function Signup() {
  const r = useRouter();
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<{name?:string;email:string;password:string}>({ resolver: zodResolver(schema) });
  return (
    <div className="p-8 max-w-md mx-auto">
      <Card className="p-6 space-y-4">
        <h2 className="text-xl font-semibold">Sign up</h2>
        <form
          onSubmit={handleSubmit(async (v) => {
            const res = await fetch("/api/signup", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(v) });
            if (!res.ok) { const j = await res.json().catch(()=>({})); alert(j.error || "Error"); return; }
            r.push("/login");
          })}
          className="space-y-3"
        >
          <Input placeholder="Name (optional)" {...register("name")} />
          <Input type="email" placeholder="Email" {...register("email")} />
          {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          <Input type="password" placeholder="Password (min 6)" {...register("password")} />
          {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          <Button type="submit" disabled={isSubmitting}>Create account</Button>
        </form>
      </Card>
    </div>
  );
}
EOF
cat > src/app/dashboard/page.tsx <<'EOF'
import { getServerSession } from "next-auth";
import { authOptions } from "@/auth/auth";
import { redirect } from "next/navigation";
export default async function Dashboard() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect("/login");
  return (
    <main className="p-8 space-y-4">
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p>Signed in as: {session.user.email}</p>
    </main>
  );
}
EOF


# ---- custom error page for /api/auth/error ----
mkdir -p src/app/api/auth/error
cat > src/app/api/auth/error/route.ts <<'EOF'
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ error: "Authentication error occurred." }, { status: 400 });
}
EOF

# Create harmless src/proxy.ts placeholder for Next.js 16+
if [ ! -f src/proxy.ts ]; then
  cat > src/proxy.ts <<'EOF'
// src/proxy.ts
// Placeholder for Next.js 16+ (proxy API not available)
export default function proxy() {
  // No-op: proxy API is not supported in this Next.js version.
  return;
}
EOF
else
  echo "src/proxy.ts already exists."
fi

# # Create src/proxy.ts for Next.js 16+ (replaces deprecated middleware.ts)
# if [ ! -f src/proxy.ts ]; then
#   cat > src/proxy.ts <<'EOF'
# import { proxy } from "next/server";
# export default proxy((request) => {
#   // Add custom proxy logic here if needed
#   return Response.next();
# });
# EOF
# else
#   echo "src/proxy.ts already exists."
# fi

# ---- SpecKit (init IN-PLACE; do NOT pass a project name with --here) ----
if ! command -v specify >/dev/null 2>&1; then
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
fi
uvx --from git+https://github.com/github/spec-kit.git specify init . --force --ai codex || \
specify init . --force --ai codex || true
# uvx --from git+https://github.com/github/spec-kit.git specify init . --here --force --ai codex || \
# specify init . --here --force --ai codex || true

# ---- Codex CLI check ----
if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI not found. Installing via npm..."
  npm install -g @openai/codex
  if command -v codex >/dev/null 2>&1; then
    echo "Codex CLI installed successfully."
  else
    echo "Codex CLI installation failed. Please check https://github.com/openai/codex for manual instructions."
  fi
fi

# ---- CI + scripts ----
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint || true
      - run: pnpm typecheck
      - run: pnpm build
EOF
node - <<'EOF'
const fs = require('fs'); const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.scripts ||= {}; pkg.scripts.typecheck = pkg.scripts.typecheck || "tsc --noEmit";
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
EOF

# ---- install + prisma client + db ----
pnpm install
# approve prisma postinstall if pnpm requires it (interactive)
if pnpm help approve-builds >/dev/null 2>&1; then pnpm approve-builds || true; fi
pnpm prisma generate
pnpm prisma db push

# ---- create test user ----
node - <<'EOF'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();
(async () => {
  const email = 'test@example.com';
  const password = 'test1234';
  const name = 'Test User';
  const hash = await bcrypt.hash(password, 12);
  const exists = await prisma.user.findUnique({ where: { email } });
  if (!exists) {
    await prisma.user.create({ data: { email, password: hash, name } });
    console.log('Test user created:');
    console.log('Email:', email);
    console.log('Password:', password);
  } else {
    console.log('Test user already exists.');
  }
  await prisma.$disconnect();
})();
EOF

# ---- pin and initial commit ----
pnpm up --save-exact
git add -A
git commit -m "scaffold: Next.js + Redux + RTKQ + shadcn + next-themes + Auth.js + Prisma + SpecKit + Sonner"

echo "Done. Run: pnpm dev  → /signup → /login → /dashboard"
