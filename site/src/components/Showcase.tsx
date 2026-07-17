import {
  ChevronLeft,
  Download,
  Eye,
  Folder,
  FileCode,
  FileText,
  LayoutGrid,
  Lock,
  Plus,
  RefreshCw,
  Search,
  Terminal,
} from "lucide-react";

// The mocks are hand-built from the app's own widgets and stay dark in both
// page themes, like AppWindow. Hosts use documentation IP ranges only.

const TABS = [
  { name: "prod-web-01", active: true },
  { name: "db-master", active: false },
];

const TERMINAL_LINES: { text: string; prompt?: boolean; muted?: boolean }[] = [
  { text: "deploy@prod-web-01:~$ uptime", prompt: true },
  {
    text: " 14:32:07 up 42 days, 3:11,  load average: 0.08, 0.12, 0.09",
    muted: true,
  },
  { text: "deploy@prod-web-01:~$ docker ps --format '{{.Names}}'", prompt: true },
  { text: "web   api   redis   postgres", muted: true },
  { text: "deploy@prod-web-01:~$", prompt: true },
];

function TerminalMock() {
  return (
    <div className="overflow-hidden rounded-2xl border border-[#1e2a26] bg-[#0a0f0d] shadow-2xl shadow-black/40 ring-1 ring-white/5">
      {/* Tab bar */}
      <div className="flex items-center gap-1 border-b border-[#1e2a26] px-3 pt-3">
        {TABS.map((t) => (
          <div
            key={t.name}
            className={`flex items-center gap-2 rounded-t-lg px-3 py-2 text-xs ${
              t.active
                ? "bg-[#101917] text-[#e6f1ec]"
                : "text-[#8ca096]"
            }`}
          >
            <Terminal className="h-3.5 w-3.5" />
            {t.name}
          </div>
        ))}
        <Plus className="ml-1 h-4 w-4 text-[#8ca096]" />
      </div>

      {/* Terminal body */}
      <div className="space-y-1.5 px-4 py-4 font-mono text-[13px] leading-relaxed">
        {TERMINAL_LINES.map((line, i) => (
          <p
            key={i}
            className={line.muted ? "text-[#8ca096]" : "text-[#e6f1ec]"}
          >
            {line.text}
            {i === TERMINAL_LINES.length - 1 && (
              <span
                className="ml-1 inline-block h-[15px] w-[7px] translate-y-0.5 bg-[#00e599]"
                style={{ animation: "blink 1s step-end infinite" }}
              />
            )}
          </p>
        ))}
      </div>

      {/* Key bar */}
      <div className="flex items-center gap-2 border-t border-[#1e2a26] px-4 py-2.5 text-[#8ca096]">
        {["Ctrl", "Tab", "Esc"].map((k) => (
          <span
            key={k}
            className="rounded-md bg-[#1a2420] px-2 py-1 font-mono text-[11px] text-[#c2cfc9]"
          >
            {k}
          </span>
        ))}
        <Search className="ml-auto h-4 w-4" />
      </div>
    </div>
  );
}

interface Entry {
  name: string;
  kind: "folder" | "file" | "code";
  size: string;
}

const ENTRIES: Entry[] = [
  { name: "releases", kind: "folder", size: "" },
  { name: "shared", kind: "folder", size: "" },
  { name: "composer.json", kind: "code", size: "1.1 KB" },
  { name: "index.php", kind: "code", size: "2.4 KB" },
  { name: "deploy.log", kind: "file", size: "88 KB" },
];

function EntryIcon({ kind }: { kind: Entry["kind"] }) {
  if (kind === "folder") return <Folder className="h-[18px] w-[18px] text-[#00e599]" />;
  if (kind === "code") return <FileCode className="h-[18px] w-[18px] text-[#8ca096]" />;
  return <FileText className="h-[18px] w-[18px] text-[#8ca096]" />;
}

function SftpMock() {
  return (
    <div className="overflow-hidden rounded-2xl border border-[#1e2a26] bg-[#0a0f0d] shadow-2xl shadow-black/40 ring-1 ring-white/5">
      {/* App bar */}
      <div className="flex items-center gap-2.5 border-b border-[#1e2a26] px-4 py-3">
        <ChevronLeft className="h-[18px] w-[18px] text-[#8ca096]" />
        <span className="truncate font-mono text-xs text-[#c2cfc9]">
          /var/www/prod-web-01
        </span>
        <div className="ml-auto flex items-center gap-3 text-[#8ca096]">
          <Eye className="h-[17px] w-[17px]" />
          <LayoutGrid className="h-[17px] w-[17px]" />
          <Lock className="h-[17px] w-[17px] text-[#00e599]" />
          <RefreshCw className="h-[17px] w-[17px]" />
        </div>
      </div>

      {/* Listing */}
      <div className="py-1">
        {ENTRIES.map((e) => (
          <div
            key={e.name}
            className="flex items-center gap-3 px-4 py-2.5 text-sm"
          >
            <EntryIcon kind={e.kind} />
            <span className="flex-1 truncate text-[#e6f1ec]">{e.name}</span>
            <span className="font-mono text-xs text-[#8ca096]">{e.size}</span>
          </div>
        ))}
      </div>

      {/* Transfer bar */}
      <div className="border-t border-[#1e2a26] px-4 py-3">
        <div className="flex items-center justify-between text-xs">
          <span className="flex items-center gap-2 text-[#c2cfc9]">
            <Download className="h-3.5 w-3.5 text-[#00e599]" />
            backup.tar.gz
          </span>
          <span className="font-mono text-[#8ca096]">62%</span>
        </div>
        <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-[#1a2420]">
          <div className="h-full w-[62%] rounded-full bg-[#00e599]" />
        </div>
      </div>
    </div>
  );
}

function Caption({ title, body }: { title: string; body: string }) {
  return (
    <div>
      <h3 className="text-xl font-bold tracking-tight sm:text-2xl">{title}</h3>
      <p className="mt-3 leading-relaxed text-muted-foreground">{body}</p>
    </div>
  );
}

export function Showcase() {
  return (
    <section id="showcase" className="mx-auto max-w-6xl px-5 py-12 md:py-16">
      <div className="max-w-2xl">
        <p className="font-mono text-xs uppercase tracking-widest text-accent-ink">
          A closer look
        </p>
        <h2 className="mt-3 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          See it in action.
        </h2>
      </div>

      <div className="mt-12 grid items-center gap-8 md:grid-cols-2 md:gap-12">
        <Caption
          title="A real terminal, in tabs"
          body="Full xterm sessions with copy, paste, select all, and find-in-scrollback. Keep up to ten servers open, each holding its own scrollback."
        />
        <TerminalMock />
      </div>

      <div className="mt-16 grid items-center gap-8 md:grid-cols-2 md:gap-12">
        <SftpMock />
        <Caption
          title="Files, without a second app"
          body="Browse, upload, download and open files over SFTP on their own connection. Read-only by default, so a stray tap on production changes nothing until you unlock it."
        />
      </div>
    </section>
  );
}
