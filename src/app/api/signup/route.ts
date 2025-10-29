import bcrypt from "bcryptjs";
import { NextResponse } from "next/server";
import { prisma } from "@/auth/prisma";

export async function POST(req: Request) {
  const { email, password, name } = await req.json().catch(() => ({}));

  if (!email || !password) {
    return NextResponse.json({ error: "Invalid" }, { status: 400 });
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return NextResponse.json({ error: "Exists" }, { status: 409 });
  }

  const hash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({ data: { email, password: hash, name } });

  return NextResponse.json({ id: user.id, email: user.email });
}
