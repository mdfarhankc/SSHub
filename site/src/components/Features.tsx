import { Check } from "lucide-react";
import { EXTRAS, FEATURES } from "@/lib/site";

export function Features() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-5 py-20 md:py-28">
      <div className="max-w-2xl">
        <p className="font-mono text-xs uppercase tracking-widest text-accent-ink">
          Features
        </p>
        <h2 className="mt-3 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          Built for people who live in the terminal.
        </h2>
        <p className="mt-4 text-lg leading-relaxed text-muted-foreground">
          The essentials done well, with the security details handled for you.
          No accounts, no cloud, no telemetry.
        </p>
      </div>

      <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f) => (
          <div
            key={f.title}
            className="group rounded-2xl border border-border bg-card p-6 transition-colors hover:border-primary/40"
          >
            <div className="flex items-center justify-between">
              <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary/10 text-accent-ink">
                <f.icon className="h-5 w-5" />
              </div>
              <span className="font-mono text-[10px] uppercase tracking-widest text-muted-foreground">
                {f.label}
              </span>
            </div>
            <h3 className="mt-5 text-lg font-semibold tracking-tight">
              {f.title}
            </h3>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              {f.body}
            </p>
          </div>
        ))}
      </div>

      <div className="mt-4 rounded-2xl border border-border bg-card p-6">
        <div className="flex flex-wrap gap-x-6 gap-y-3">
          {EXTRAS.map((e) => (
            <span
              key={e}
              className="flex items-center gap-2 text-sm text-muted-foreground"
            >
              <Check className="h-4 w-4 text-accent-ink" />
              {e}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
