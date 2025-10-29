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
