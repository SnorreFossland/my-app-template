"use client";

import { z } from "zod";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

const schema = z.object({
  name: z.string().optional(),
  email: z.string().email(),
  password: z.string().min(6),
});

export default function Signup() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<{ name?: string; email: string; password: string }>({ resolver: zodResolver(schema) });

  return (
    <div className="mx-auto max-w-md p-8">
      <Card className="space-y-4 p-6">
        <h2 className="text-xl font-semibold">Sign up</h2>
        <form
          onSubmit={handleSubmit(async (values) => {
            const res = await fetch("/api/signup", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(values),
            });

            if (!res.ok) {
              const payload = await res.json().catch(() => ({}));
              alert(payload.error ?? "Error creating account");
              return;
            }

            router.push("/login");
          })}
          className="space-y-3"
        >
          <Input placeholder="Name (optional)" {...register("name")} />
          <Input type="email" placeholder="Email" {...register("email")} />
          {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          <Input type="password" placeholder="Password (min 6)" {...register("password")} />
          {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          <Button type="submit" disabled={isSubmitting}>
            Create account
          </Button>
        </form>
      </Card>
    </div>
  );
}
