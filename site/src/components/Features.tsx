import { Check, Wrench } from "lucide-react";
import { EXTRAS, FEATURES, ROADMAP } from "@/lib/site";

export function Features() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-5 py-16 md:py-24">
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

      <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f) => (
          <div
            key={f.title}
            className="group rounded-2xl border border-border bg-card p-6 transition duration-200 hover:-translate-y-0.5 hover:border-primary/40"
          >
            <div className="flex items-center justify-between">
              <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary/10 text-accent-ink transition-colors group-hover:bg-primary/15">
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

      <div className="mt-16 border-t border-border pt-10">
        <p className="font-mono text-xs uppercase tracking-widest text-muted-foreground">
          Also included
        </p>
        <ul className="mt-6 grid gap-x-8 gap-y-4 sm:grid-cols-2 lg:grid-cols-3">
          {EXTRAS.map((e) => (
            <li
              key={e}
              className="flex items-center gap-2.5 text-sm text-foreground/80"
            >
              <Check className="h-4 w-4 shrink-0 text-accent-ink" />
              {e}
            </li>
          ))}
        </ul>
      </div>

      <div className="mt-14 border-t border-dashed border-border pt-10">
        <p className="font-mono text-xs uppercase tracking-widest text-muted-foreground">
          On the roadmap
        </p>
        <ul className="mt-6 grid gap-x-8 gap-y-4 sm:grid-cols-2 lg:grid-cols-3">
          {ROADMAP.map((r) => (
            <li
              key={r}
              className="flex items-center gap-2.5 text-sm text-muted-foreground/80"
            >
              <Wrench className="h-4 w-4 shrink-0 text-muted-foreground/60" />
              {r}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
