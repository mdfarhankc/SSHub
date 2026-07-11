import {
  KeyRound,
  ShieldCheck,
  Radio,
  TerminalSquare,
  RefreshCw,
  Archive,
  type LucideIcon,
} from "lucide-react";

export const VERSION = "3.0.0";
export const GITHUB_URL = "https://github.com/mdfarhankc/SSHub";
export const RELEASES_URL = `${GITHUB_URL}/releases/latest`;

export const PLATFORMS = ["Windows", "macOS", "Linux", "Android"] as const;

export interface Feature {
  icon: LucideIcon;
  label: string;
  title: string;
  body: string;
}

export const FEATURES: Feature[] = [
  {
    icon: KeyRound,
    label: "auth",
    title: "Password or SSH key",
    body: "Connect with a password or a private key (OpenSSH, RSA, or EC), with an optional key passphrase and file import.",
  },
  {
    icon: ShieldCheck,
    label: "trust",
    title: "Host key verification",
    body: "SSHub remembers each server's fingerprint and refuses to connect if it changes, so you notice when something is off.",
  },
  {
    icon: Radio,
    label: "status",
    title: "Live server status",
    body: "Every card shows whether the host is online, offline, or being checked, before you open a session.",
  },
  {
    icon: TerminalSquare,
    label: "terminal",
    title: "A real terminal",
    body: "A full xterm terminal with copy, paste, select all, and find-in-scrollback. Not a cut-down shell.",
  },
  {
    icon: RefreshCw,
    label: "resilience",
    title: "Auto-reconnect",
    body: "Dropped connections retry on their own with backoff, and only report a failure once the retries are spent.",
  },
  {
    icon: Archive,
    label: "backups",
    title: "Encrypted backups",
    body: "Export and import your servers, encrypted by default. Private keys never leave your machine.",
  },
];

export const EXTRAS = [
  "Snippets",
  "Keyboard shortcuts",
  "App lock",
  "Light and dark themes",
  "In-app update check",
  "Color-tagged servers",
] as const;
