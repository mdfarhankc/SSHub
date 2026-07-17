import {
  KeyRound,
  ShieldCheck,
  Radio,
  TerminalSquare,
  RefreshCw,
  Archive,
  FolderOpen,
  Layers,
  Lock,
  type LucideIcon,
} from "lucide-react";

export const VERSION = "4.0.0";
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
    icon: FolderOpen,
    label: "files",
    title: "Built-in file browser",
    body: "Browse, upload, download and open files over SFTP, in a list or a grid. No second app, no separate login.",
  },
  {
    icon: Layers,
    label: "sessions",
    title: "Tabbed sessions",
    body: "Keep up to ten servers open at once. Every tab holds its own scrollback, and switching is a keystroke.",
  },
  {
    icon: Lock,
    label: "safety",
    title: "Read-only by default",
    body: "The file browser cannot change anything on your server until you unlock it, so a misclick on production stays harmless.",
  },
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

export const ROADMAP = [
  "Folder upload and download",
  "In-place remote file editing",
  "Multi-select and batch actions",
  "A transfer queue",
  "Resume interrupted transfers",
  "File permissions editing",
  "Search within a folder",
] as const;

export type CompareValue = "yes" | "no" | "partial";

export interface CompareRow {
  label: string;
  // Aligned to COMPARE_APPS order.
  values: CompareValue[];
}

export const COMPARE_APPS = ["SSHub", "PuTTY", "Termius", "MobaXterm"] as const;

export const COMPARE_ROWS: CompareRow[] = [
  { label: "Free to use", values: ["yes", "yes", "partial", "partial"] },
  { label: "Open source", values: ["yes", "yes", "no", "no"] },
  { label: "Desktop and mobile", values: ["yes", "no", "yes", "no"] },
  { label: "Built-in file browser", values: ["yes", "no", "yes", "yes"] },
  { label: "Tabbed sessions", values: ["yes", "no", "yes", "yes"] },
  { label: "Works offline, no account", values: ["yes", "yes", "no", "yes"] },
  { label: "Modern, themeable interface", values: ["yes", "no", "yes", "partial"] },
];

export interface Faq {
  q: string;
  a: string;
}

export const FAQS: Faq[] = [
  {
    q: "Is SSHub free?",
    a: "Yes. SSHub is free and open source under the GPL-3.0 license. There are no accounts, no paid tiers, and no ads.",
  },
  {
    q: "Where are my passwords and keys stored?",
    a: "In your operating system's secure store: Windows Credential Manager, the macOS Keychain, and the equivalent keychain on Linux and Android. They are never written in plain text, and private keys stay on your machine.",
  },
  {
    q: "Does SSHub send my data anywhere?",
    a: "No. There is no cloud, no telemetry, and no analytics. Your servers are saved locally on your device, and nothing leaves it unless you export a backup yourself.",
  },
  {
    q: "Why does my system warn that the app is from an unknown developer?",
    a: "The builds are not code-signed yet, so Windows, macOS, and Android show a one-time warning the first time you open the app. It is expected, and the install guide on GitHub has the steps to get past it on each platform.",
  },
  {
    q: "Which platforms does it run on?",
    a: "Windows, macOS, Linux, and Android. Desktop is the primary target. There is no web version, because browsers cannot open the raw TCP connections that SSH needs.",
  },
  {
    q: "Can I connect with an SSH key?",
    a: "Yes. SSHub supports OpenSSH, RSA, and EC private keys, with an optional key passphrase, alongside plain password login.",
  },
  {
    q: "Can I transfer files?",
    a: "Yes. A built-in SFTP browser lets you browse, upload, download, and open files in a list or a grid, over its own connection. It starts in read-only mode by default, so a stray tap cannot change anything until you unlock it.",
  },
  {
    q: "How do I move my servers to another computer?",
    a: "Use the encrypted backup export, then import the file on the other machine. Backups are encrypted by default, and private keys are deliberately left out of them.",
  },
  {
    q: "Can I contribute?",
    a: "SSHub is not accepting external code contributions right now, so pull requests will be closed. Bug reports and feature ideas are welcome though, through the issue templates on GitHub.",
  },
];
