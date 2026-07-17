import { useEffect, useState } from "react";
import { Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { GithubIcon } from "@/components/GithubIcon";
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
