import {
  ArrowRight,
  CircleHelp,
  History,
  MoreHorizontal,
  Plus,
  RefreshCw,
  Search,
  Server,
  Settings,
  Terminal,
  Zap,
} from "lucide-react";

type Status = "online" | "offline" | "checking";

interface Node {
  label: string;
  host: string;
  desc: string;
  accent: string;
  status: Status;
  lastSeen: string;
}

// Server accent palette from core/theme/server_colors.dart.
const SERVERS: Node[] = [
  {
    label: "prod-web-01",
    host: "203.0.113.10",
    desc: "Primary web server",
    accent: "#3b82f6",
    status: "online",
    lastSeen: "Last seen: 2m ago",
  },
  {
    label: "db-master",
    host: "10.0.0.5",
    desc: "Postgres primary",
    accent: "#22c55e",
    status: "online",
    lastSeen: "Last seen: just now",
  },
  {
    label: "staging",
    host: "198.51.100.4",
    desc: "Staging environment",
    accent: "#a855f7",
    status: "offline",
    lastSeen: "Last seen: 3h ago",
  },
  {
    label: "backup-eu",
    host: "192.0.2.7",
    desc: "Nightly backups",
    accent: "#f59e0b",
    status: "checking",
    lastSeen: "Last seen: 1d ago",
  },
];

// Reachability colors from server_card.dart: online = primary (mint),
// offline = muted, checking = warning amber.
const STATUS_COLOR: Record<Status, string> = {
  online: "#00e599",
  offline: "#5b6b64",
  checking: "#f59e0b",
};

function ServerCard({ s }: { s: Node }) {
  return (
    <div className="flex min-h-[168px] flex-col rounded-[20px] border border-[#1e2a26] bg-[#0e1512] p-4">
      <div className="flex items-start gap-3">
        <div className="relative shrink-0">
          <div
            className="flex h-10 w-10 items-center justify-center rounded-xl"
            style={{ backgroundColor: `${s.accent}1a`, color: s.accent }}
          >
            <Terminal className="h-5 w-5" />
          </div>
          <span
            className="absolute -bottom-1 -right-1 h-3.5 w-3.5 rounded-full ring-[2.5px] ring-[#0e1512]"
            style={{
              backgroundColor: STATUS_COLOR[s.status],
              animation:
                s.status === "checking"
                  ? "pulse-dot 1.6s ease-in-out infinite"
                  : undefined,
            }}
          />
        </div>

        <div className="min-w-0 flex-1">
          <p className="truncate text-[15px] font-bold text-[#e6f1ec]">
            {s.label}
          </p>
          <p className="truncate font-mono text-xs text-[#8ca096]">{s.host}</p>
        </div>

        <MoreHorizontal className="h-5 w-5 shrink-0 text-[#8ca096]" />
      </div>

      <p className="mt-3 truncate text-xs text-[#8ca096]">{s.desc}</p>

      <div className="mt-auto flex items-center justify-between pt-4">
        <span className="rounded-md bg-[#1a2420] px-2 py-1 text-[10px] font-semibold text-[#c2cfc9]">
          {s.lastSeen}
        </span>
        <ArrowRight className="h-[18px] w-[18px] text-[#8ca096]" />
      </div>
    </div>
  );
}

function Stat({
  icon: Icon,
  value,
  label,
}: {
  icon: typeof Server;
  value: string;
  label: string;
}) {
  return (
    <div className="flex items-center gap-1.5">
      <Icon className="h-4 w-4 text-[#00e599]" />
      <span className="text-[15px] font-bold text-[#e6f1ec]">{value}</span>
      <span className="text-sm text-[#8ca096]">{label}</span>
    </div>
  );
}

// A faithful reconstruction of the SSHub home screen, built from the app's
// own widgets (home_page.dart, home_header.dart, server_card.dart). Stays dark
// in both page themes because it depicts the app's dark UI.
export function AppWindow() {
  return (
    <div className="overflow-hidden rounded-2xl border border-[#1e2a26] bg-[#0a0f0d] shadow-2xl shadow-black/40 ring-1 ring-white/5">
      <div className="p-4 sm:p-5">
        {/* App bar: action icons */}
        <div className="flex items-center justify-end gap-1 text-[#8ca096]">
          <RefreshCw className="mx-1.5 h-[18px] w-[18px]" />
          <CircleHelp className="mx-1.5 h-[18px] w-[18px]" />
          <Zap className="mx-1.5 h-[18px] w-[18px]" />
          <Settings className="mx-1.5 h-[18px] w-[18px]" />
        </div>

        {/* Title + stats */}
        <div className="mt-1 flex items-end justify-between gap-4">
          <h3 className="text-2xl font-extrabold tracking-tight text-[#e6f1ec]">
            SSHub
          </h3>
          <div className="flex items-center gap-5">
            <Stat icon={Server} value="4" label="Servers" />
            <Stat icon={History} value="2" label="Connected" />
          </div>
        </div>

        {/* Search + Add */}
        <div className="mt-5 flex items-center gap-3">
          <div className="flex h-11 flex-1 items-center gap-2.5 rounded-xl bg-[#1a2420]/60 px-3.5 text-[#8ca096]">
            <Search className="h-4 w-4" />
            <span className="truncate text-sm">
              Search your infrastructure...
            </span>
          </div>
          <button
            type="button"
            className="flex h-11 items-center gap-2 rounded-xl bg-[#00e599] px-4 text-sm font-semibold text-[#04140e]"
          >
            <Plus className="h-4 w-4" />
            <span className="hidden sm:inline">Add Server</span>
          </button>
        </div>

        {/* Server grid */}
        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
          {SERVERS.map((s) => (
            <ServerCard key={s.label} s={s} />
          ))}
        </div>
      </div>
    </div>
  );
}
