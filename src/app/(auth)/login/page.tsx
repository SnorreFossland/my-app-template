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
