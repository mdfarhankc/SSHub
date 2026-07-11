import { Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { GithubIcon } from "@/components/GithubIcon";
import { AppWindow } from "@/components/AppWindow";
import { useOS, OS_TO_PLATFORM } from "@/hooks/useOS";
import { WaveBackground } from "@/components/WaveBackground";
import { GITHUB_URL, PLATFORMS, RELEASES_URL, VERSION } from "@/lib/site";

export function Hero() {
  const { os, downloadLabel } = useOS();
  const activePlatform = OS_TO_PLATFORM[os];
  return (
    <section id="top" className="relative overflow-hidden">
      {/* Animated diagonal light ribbons */}
      <div className="pointer-events-none absolute inset-0">
        <WaveBackground />
      </div>

      {/* Ambient mint glow */}
      <div
        aria-hidden
        className="pointer-events-none absolute left-1/2 top-[-10%] h-[520px] w-[820px] max-w-[95vw] -translate-x-1/2 rounded-full opacity-40 blur-3xl"
        style={{
          background:
            "radial-gradient(closest-side, color-mix(in srgb, var(--primary) 22%, transparent), transparent)",
        }}
      />

      <div className="relative z-10 mx-auto max-w-6xl px-5 pb-20 pt-28 sm:pt-36 md:pb-28">
        <div className="mx-auto flex max-w-3xl flex-col items-center text-center">
          <a
            href={`${GITHUB_URL}/releases/tag/v${VERSION}`}
            className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-3 py-1.5 font-mono text-xs text-muted-foreground transition-colors hover:text-foreground"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-primary" />
            v{VERSION} is out now
          </a>

          <h1 className="mt-6 text-balance text-5xl font-extrabold leading-[1.05] tracking-tight sm:text-6xl md:text-7xl">
            Every server,
            <br />
            <span className="text-accent-ink">one click away.</span>
          </h1>

          <p className="mt-6 max-w-xl text-balance text-lg leading-relaxed text-muted-foreground">
            SSHub is a fast, minimal SSH client for the desktop. Password or key
            auth, a full terminal, and your credentials encrypted on your own
            machine.
          </p>

          <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row">
            <Button asChild size="lg">
              <a href={RELEASES_URL}>
                <Download />
                {downloadLabel}
              </a>
            </Button>
            <Button asChild size="lg" variant="outline">
              <a href={GITHUB_URL}>
                <GithubIcon />
                View on GitHub
              </a>
            </Button>
          </div>

          <div className="mt-7 flex flex-wrap items-center justify-center gap-x-2 gap-y-1 font-mono text-xs uppercase tracking-widest text-muted-foreground">
            {PLATFORMS.map((p, i) => (
              <span key={p} className="flex items-center gap-2">
                {i > 0 && <span className="text-border">·</span>}
                <span className={p === activePlatform ? "text-accent-ink" : ""}>
                  {p}
                </span>
              </span>
            ))}
          </div>
        </div>

        <div
          className="mx-auto mt-16 max-w-3xl"
          style={{ animation: "rise 0.7s ease-out both" }}
        >
          <AppWindow />
        </div>
      </div>
    </section>
  );
}
