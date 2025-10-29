"use client";

import { z } from "zod";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

const schema = z.object({ email: z.string().email(), password: z.string().min(6) });

export default function Login() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<{ email: string; password: string }>({ resolver: zodResolver(schema) });

  return (
    <div className="mx-auto max-w-md p-8">
      <Card className="space-y-4 p-6">
        <h2 className="text-xl font-semibold">Login</h2>
        <form
          onSubmit={handleSubmit(async (values) => {
            const response = await signIn("credentials", {
              redirect: false,
              email: values.email,
              password: values.password,
            });

            if (!response || response.error) {
              alert("Invalid credentials");
              return;
            }

            router.push("/dashboard");
          })}
          className="space-y-3"
        >
          <Input type="email" placeholder="Email" {...register("email")} />
          {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          <Input type="password" placeholder="Password" {...register("password")} />
          {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          <Button type="submit" disabled={isSubmitting}>
            Sign in
          </Button>
        </form>
      </Card>
    </div>
  );
}
