import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft, Check, Copy, Search } from "lucide-react";
import { GUIDE } from "@/lib/guide";
import { Logo } from "@/components/Logo";

export function Guide() {
  const [query, setQuery] = useState("");
  const [copied, setCopied] = useState<string | null>(null);

  const q = query.trim().toLowerCase();
  const categories = useMemo(() => {
    if (!q) return GUIDE;
    return GUIDE.map((category) => ({
      ...category,
      commands: category.commands.filter(
        (c) =>
          c.command.toLowerCase().includes(q) ||
          c.description.toLowerCase().includes(q)
      ),
    })).filter((category) => category.commands.length > 0);
  }, [q]);

  const copy = async (command: string) => {
    try {
      await navigator.clipboard.writeText(command);
      setCopied(command);
      setTimeout(() => setCopied((c) => (c === command ? null : c)), 1200);
    } catch {
      // Clipboard access can be blocked; nothing else to do.
    }
  };

  const jumpTo = (id: string) =>
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="sticky top-0 z-40 border-b border-border bg-background/80 backdrop-blur-xl">
        <div className="mx-auto flex max-w-5xl items-center gap-4 px-4 py-3">
          <Link
            to="/"
            className="flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            <span className="hidden sm:inline">Back to site</span>
          </Link>
          <div className="flex items-center gap-2">
            <Logo className="h-7 w-7" />
            <span className="font-bold tracking-tight">Command guide</span>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 pb-24 pt-10">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Command guide
        </h1>
        <p className="mt-3 max-w-2xl text-muted-foreground">
          A quick reference for working on servers: Linux, systemd, Postgres,
          Docker, Nginx, Git and more. Not SSHub-specific. Copy a command and
          paste it into your session.
        </p>

        <div className="sticky top-[60px] z-30 -mx-4 mt-6 bg-background/90 px-4 py-3 backdrop-blur-xl">
          <div className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search commands..."
              aria-label="Search commands"
              className="w-full rounded-lg border border-border bg-card/60 py-2.5 pl-10 pr-3 text-sm outline-none transition focus:border-primary/50"
            />
          </div>
          {!q && (
            <div className="mt-3 flex flex-wrap gap-2">
              {GUIDE.map((category) => (
                <button
                  key={category.id}
                  type="button"
                  onClick={() => jumpTo(category.id)}
                  className="rounded-full border border-border bg-card/60 px-3 py-1 text-xs text-muted-foreground transition-colors hover:text-foreground"
                >
                  {category.title}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="mt-8 space-y-12">
          {categories.map((category) => {
            const Icon = category.icon;
            return (
              <section key={category.id} id={category.id} className="scroll-mt-36">
                <div className="flex items-center gap-2.5">
                  <Icon className="h-5 w-5 text-primary" />
                  <h2 className="text-xl font-bold tracking-tight">
                    {category.title}
                  </h2>
                </div>
                <div className="mt-4 divide-y divide-border overflow-hidden rounded-xl border border-border">
                  {category.commands.map((cmd) => (
                    <div
                      key={cmd.command}
                      className="group flex items-start gap-3 bg-card/40 px-4 py-3 transition-colors hover:bg-card/70"
                    >
                      <div className="min-w-0 flex-1">
                        <code className="block break-all font-mono text-sm text-foreground">
                          {cmd.command}
                        </code>
                        <p className="mt-1 text-sm text-muted-foreground">
                          {cmd.description}
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() => copy(cmd.command)}
                        aria-label="Copy command"
                        className="mt-0.5 shrink-0 rounded-md border border-border bg-background/60 p-1.5 text-muted-foreground transition-all hover:text-foreground sm:opacity-0 sm:group-hover:opacity-100"
                      >
                        {copied === cmd.command ? (
                          <Check className="h-4 w-4 text-primary" />
                        ) : (
                          <Copy className="h-4 w-4" />
                        )}
                      </button>
                    </div>
                  ))}
                </div>
              </section>
            );
          })}
          {categories.length === 0 && (
            <p className="py-12 text-center text-muted-foreground">
              No commands match "{query}".
            </p>
          )}
        </div>
      </main>
    </div>
  );
}
