import { useEffect, useState } from "react";
import { Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { GithubIcon } from "@/components/GithubIcon";
import { GitHubStars } from "@/components/GitHubStars";
import { Logo } from "@/components/Logo";
import { ThemeToggle } from "@/components/ThemeToggle";
import { cn } from "@/lib/utils";
import { GITHUB_URL, RELEASES_URL } from "@/lib/site";

const NAV = [
  { label: "Features", href: "#features" },
  { label: "Compare", href: "#compare" },
  { label: "FAQ", href: "#faq" },
  { label: "Download", href: "#download" },
  { label: "GitHub", href: GITHUB_URL },
];

export function Header() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header className="fixed inset-x-0 top-0 z-50 flex justify-center px-4">
      <div
        className={cn(
          "flex w-full items-center justify-between gap-4 rounded-full px-4 transition-all duration-300 ease-out sm:px-5",
          "max-w-6xl",
          scrolled
            ? "mt-3 h-14 border border-border bg-background/70 shadow-lg shadow-black/10 backdrop-blur-xl"
            : "mt-0 h-16 border border-transparent bg-transparent"
        )}
      >
        <a href="#top" className="flex items-center gap-2.5">
          <Logo className="h-11 w-11" />
          <span className="text-xl font-bold tracking-tight">SSHub</span>
          <span className="ml-1 hidden items-center gap-1 rounded-full border border-border bg-card/60 px-2 py-0.5 font-mono text-xs text-muted-foreground backdrop-blur-sm sm:inline-flex">
            <Star className="h-3 w-3" />
            open source
          </span>
        </a>

        <nav className="hidden items-center gap-1 md:flex">
          {NAV.map((item) => (
            <a
              key={item.label}
              href={item.href}
              className="rounded-md px-3 py-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-1.5">
          <ThemeToggle />
          {/* Anchor the annotation to the star button so it tracks the button,
              not the full-width header. */}
          <div className="relative hidden sm:block">
            <GitHubStars />
            <div
              aria-hidden
              className={cn(
                "pointer-events-none absolute right-[44px] top-[calc(100%+0.8rem)] hidden select-none items-start gap-1 text-primary transition-all duration-300 ease-out lg:flex",
                scrolled
                  ? "-translate-y-1 opacity-0"
                  : "translate-y-0 opacity-100"
              )}
            >
              <span
                className="-rotate-6 whitespace-nowrap text-2xl leading-none"
                style={{ fontFamily: "'Caveat', cursive" }}
              >
                Leave a star!
              </span>
              <svg
                viewBox="0 0 40 44"
                fill="none"
                className="-mt-5 h-11 w-10 shrink-0"
              >
                <path
                  d="M6 40C20 34 31 24 31 6"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                />
                <path
                  d="M31 6L21 11M31 6L34 17"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </div>
          </div>
          <Button asChild size="sm" className="hidden sm:inline-flex">
            <a href={RELEASES_URL}>
              <GithubIcon />
              Download
            </a>
          </Button>
        </div>
      </div>
    </header>
  );
}
