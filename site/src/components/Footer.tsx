import { Logo } from "@/components/Logo";
import { GITHUB_URL, RELEASES_URL, VERSION } from "@/lib/site";

const LINKS = [
  { label: "Features", href: "#features" },
  { label: "Compare", href: "#compare" },
  { label: "FAQ", href: "#faq" },
  { label: "Download", href: "#download" },
  { label: "GitHub", href: GITHUB_URL },
  { label: "Releases", href: RELEASES_URL },
  { label: "License", href: `${GITHUB_URL}/blob/main/LICENSE` },
];

export function Footer() {
  return (
    <footer className="border-t border-border">
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-5 py-10 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2.5">
          <Logo className="h-9 w-9" />
          <div className="leading-tight">
            <p className="text-sm font-semibold">SSHub</p>
            <p className="font-mono text-xs text-muted-foreground">
              v{VERSION} · GPL-3.0
            </p>
          </div>
        </div>

        <nav className="flex flex-wrap gap-x-6 gap-y-2">
          {LINKS.map((l) => (
            <a
              key={l.label}
              href={l.href}
              className="text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {l.label}
            </a>
          ))}
        </nav>

        <p className="text-xs text-muted-foreground">
          Built by{" "}
          <a
            href="https://github.com/mdfarhankc"
            className="text-accent-ink hover:underline"
          >
            Mohammed Farhan K C
          </a>
        </p>
      </div>
    </footer>
  );
}
