import { useEffect, useState } from "react";
import { Star } from "lucide-react";
import { GithubIcon } from "@/components/GithubIcon";
import { GITHUB_URL } from "@/lib/site";

const REPO = "mdfarhankc/SSHub";
const CACHE_KEY = "sshub_stars";
const CACHE_TTL = 1000 * 60 * 60; // Refetch at most hourly to stay under the API rate limit.

function format(count: number): string {
  if (count < 1000) return String(count);
  return (count / 1000).toFixed(1).replace(/\.0$/, "") + "k";
}

export function GitHubStars() {
  const [stars, setStars] = useState<number | null>(null);

  useEffect(() => {
    // Show the cached count immediately, then refresh if it has gone stale.
    let fresh = false;
    try {
      const raw = localStorage.getItem(CACHE_KEY);
      if (raw) {
        const { count, at } = JSON.parse(raw);
        if (typeof count === "number") setStars(count);
        fresh = Date.now() - at < CACHE_TTL;
      }
    } catch {
      // Ignore unreadable cache.
    }
    if (fresh) return;

    let cancelled = false;
    fetch(`https://api.github.com/repos/${REPO}`)
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (cancelled || !data || typeof data.stargazers_count !== "number")
          return;
        setStars(data.stargazers_count);
        try {
          localStorage.setItem(
            CACHE_KEY,
            JSON.stringify({ count: data.stargazers_count, at: Date.now() })
          );
        } catch {
          // Storage may be full or blocked; the count still shows this session.
        }
      })
      .catch(() => {
        // Offline or rate-limited; the button still links to the repo.
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <a
      href={GITHUB_URL}
      target="_blank"
      rel="noreferrer"
      aria-label="Star SSHub on GitHub"
      className="group inline-flex items-center gap-2 rounded-full border border-border bg-card/60 px-3 py-1.5 text-sm backdrop-blur-sm transition-colors hover:border-foreground/30 hover:bg-card"
    >
      <GithubIcon className="h-4 w-4" />
      <span className="flex items-center gap-1 text-muted-foreground transition-colors group-hover:text-foreground">
        <Star className="h-3.5 w-3.5 transition-colors group-hover:fill-yellow-400 group-hover:text-yellow-400" />
        <span className="font-mono tabular-nums">
          {stars === null ? "Star" : format(stars)}
        </span>
      </span>
    </a>
  );
}
