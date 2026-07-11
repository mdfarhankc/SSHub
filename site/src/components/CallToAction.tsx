import { Download, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { GithubIcon } from "@/components/GithubIcon";
import { useOS } from "@/hooks/useOS";
import { GITHUB_URL, PLATFORMS, RELEASES_URL } from "@/lib/site";

export function CallToAction() {
  const { downloadLabel } = useOS();
  return (
    <section id="download" className="mx-auto max-w-6xl px-5 pb-24">
      <div className="relative overflow-hidden rounded-3xl border border-border bg-card px-6 py-16 text-center sm:px-12">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-x-0 top-0 h-40 opacity-70 blur-3xl"
          style={{
            background:
              "radial-gradient(closest-side at 50% 0%, color-mix(in srgb, var(--primary) 20%, transparent), transparent)",
          }}
        />
        <div className="relative">
          <p className="inline-flex items-center gap-2 rounded-full border border-border bg-background px-3 py-1.5 font-mono text-xs text-muted-foreground">
            <ShieldCheck className="h-3.5 w-3.5 text-accent-ink" />
            Free and open source
          </p>
          <h2 className="mx-auto mt-6 max-w-xl text-balance text-3xl font-bold tracking-tight sm:text-4xl">
            Download SSHub and connect in seconds.
          </h2>
          <p className="mx-auto mt-4 max-w-md text-muted-foreground">
            No account, no cloud. Your servers and keys stay on your machine.
          </p>

          <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Button asChild size="lg">
              <a href={RELEASES_URL}>
                <Download />
                {downloadLabel}
              </a>
            </Button>
            <Button asChild size="lg" variant="outline">
              <a href={RELEASES_URL}>
                <GithubIcon />
                All downloads
              </a>
            </Button>
          </div>

          <p className="mt-6 font-mono text-xs uppercase tracking-widest text-muted-foreground">
            {PLATFORMS.join("  ·  ")}
          </p>
          <p className="mt-4 text-xs text-muted-foreground">
            Builds aren't code-signed yet, so your OS shows a one-time warning
            the first time you open the app.{" "}
            <a
              href={`${GITHUB_URL}#installation`}
              className="text-accent-ink hover:underline"
            >
              See the install guide.
            </a>
          </p>
        </div>
      </div>
    </section>
  );
}
