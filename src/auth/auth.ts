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
