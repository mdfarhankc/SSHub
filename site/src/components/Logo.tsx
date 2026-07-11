import { cn } from "@/lib/utils";

export function Logo({ className }: { className?: string }) {
  return (
    <img
      src={`${import.meta.env.BASE_URL}logo.png`}
      alt="SSHub logo"
      width={40}
      height={40}
      className={cn("object-contain", className)}
    />
  );
}
