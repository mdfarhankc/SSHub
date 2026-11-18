import {
  Folder,
  Shield,
  Cpu,
  HardDrive,
  Network,
  Settings,
  Package,
  Database,
  Box,
  Server,
  GitBranch,
  ArrowRightLeft,
  type LucideIcon,
} from "lucide-react";

export interface GuideCommand {
  command: string;
  description: string;
}

export interface GuideCategory {
  id: string;
  title: string;
  icon: LucideIcon;
  commands: GuideCommand[];
}

// A general developer cheatsheet, not SSHub-specific. Add entries freely; the
// page is generated from this list.
export const GUIDE: GuideCategory[] = [
  {
    id: "files",
    title: "Files and navigation",
    icon: Folder,
    commands: [
      { command: "ls -lah", description: "List files with sizes, permissions and hidden entries" },
      { command: "cd -", description: "Jump back to the previous directory" },
      { command: 'find . -name "*.log"', description: "Find files by name under the current directory" },
      { command: "du -sh *", description: "Size of each item in the current directory" },
      { command: "tail -f /var/log/syslog", description: "Follow a log file live" },
      { command: 'grep -rni "error" .', description: "Recursive, case-insensitive search with line numbers" },
      { command: "rsync -avz src/ user@host:/dest/", description: "Sync a folder to a remote host" },
    ],
  },
  {
    id: "permissions",
    title: "Permissions and ownership",
    icon: Shield,
    commands: [
      { command: "chmod 644 file", description: "Owner read and write, everyone else read only" },
      { command: "chmod +x script.sh", description: "Make a script executable" },
      { command: "chmod -R 755 dir", description: "Recursively set directory permissions" },
      { command: "chown user:group file", description: "Change the owner and group of a file" },
      { command: "sudo !!", description: "Re-run the previous command with sudo" },
    ],
  },
  {
    id: "processes",
    title: "Processes and resources",
    icon: Cpu,
    commands: [
      { command: "htop", description: "Interactive process and resource viewer" },
      { command: "ps aux --sort=-%mem | head", description: "Top processes by memory use" },
      { command: "kill -9 <pid>", description: "Force-kill a process by id" },
      { command: "pkill -f name", description: "Kill processes matching a pattern" },
      { command: "free -h", description: "Memory usage, human readable" },
      { command: "watch -n 2 <cmd>", description: "Re-run a command every two seconds" },
    ],
  },
  {
    id: "disk",
    title: "Disk and storage",
    icon: HardDrive,
    commands: [
      { command: "df -h", description: "Free and used space per filesystem" },
      { command: "du -sh /var/*", description: "Space used by each item in a directory" },
      { command: "ncdu /", description: "Interactive disk usage explorer" },
      { command: "lsblk", description: "List block devices and mount points" },
    ],
  },
  {
    id: "network",
    title: "Networking",
    icon: Network,
    commands: [
      { command: "ip a", description: "Show network interfaces and addresses" },
      { command: "ss -tulpn", description: "Listening ports and the processes behind them" },
      { command: "curl -I https://example.com", description: "Fetch only the response headers" },
      { command: "dig +short example.com", description: "Resolve a domain name quickly" },
      { command: "nc -zv host 5432", description: "Test whether a TCP port is open" },
    ],
  },
  {
    id: "systemd",
    title: "Services (systemd)",
    icon: Settings,
    commands: [
      { command: "systemctl status nginx", description: "Service state and recent log lines" },
      { command: "sudo systemctl restart nginx", description: "Restart a service" },
      { command: "sudo systemctl enable --now app", description: "Start now and on every boot" },
      { command: "journalctl -u app -f", description: "Follow a service's logs" },
      { command: 'journalctl -u app --since "1 hour ago"', description: "Logs from the last hour" },
      { command: "systemctl list-units --failed", description: "Show units that failed to start" },
    ],
  },
  {
    id: "packages",
    title: "Packages (apt)",
    icon: Package,
    commands: [
      { command: "sudo apt update && sudo apt upgrade", description: "Refresh the index and upgrade packages" },
      { command: "sudo apt install -y pkg", description: "Install a package without prompting" },
      { command: "apt list --installed | grep name", description: "Check whether a package is installed" },
      { command: "sudo apt autoremove", description: "Remove dependencies nothing needs anymore" },
    ],
  },
  {
    id: "postgres",
    title: "PostgreSQL",
    icon: Database,
    commands: [
      { command: "psql -U user -d dbname", description: "Connect to a database" },
      { command: "sudo -u postgres psql", description: "Open psql as the postgres superuser" },
      { command: "\\l", description: "List databases (inside psql)" },
      { command: "\\dt", description: "List tables in the current database" },
      { command: "\\d tablename", description: "Describe a table's columns and indexes" },
      { command: "pg_dump -U user dbname > dump.sql", description: "Back up a database to a file" },
      { command: "psql -U user dbname < dump.sql", description: "Restore a database from a dump" },
      { command: "SELECT pg_size_pretty(pg_database_size('dbname'));", description: "Show a database's size" },
    ],
  },
  {
    id: "docker",
    title: "Docker",
    icon: Box,
    commands: [
      { command: "docker ps", description: "List running containers" },
      { command: "docker ps -a", description: "List all containers, including stopped" },
      { command: "docker logs -f <name>", description: "Follow a container's logs" },
      { command: "docker exec -it <name> bash", description: "Open a shell inside a running container" },
      { command: "docker compose up -d", description: "Start services in the background" },
      { command: "docker compose down", description: "Stop and remove the services" },
      { command: "docker system df", description: "Disk space used by Docker" },
      { command: "docker image prune -a", description: "Remove images no container uses" },
    ],
  },
  {
    id: "nginx",
    title: "Nginx",
    icon: Server,
    commands: [
      { command: "sudo nginx -t", description: "Test the configuration for errors" },
      { command: "sudo systemctl reload nginx", description: "Apply config without dropping connections" },
      { command: "tail -f /var/log/nginx/error.log", description: "Follow the error log" },
      { command: "tail -f /var/log/nginx/access.log", description: "Follow the access log" },
    ],
  },
  {
    id: "git",
    title: "Git",
    icon: GitBranch,
    commands: [
      { command: "git status -sb", description: "Short status with branch and ahead/behind" },
      { command: "git log --oneline --graph --decorate -20", description: "Compact history as a graph" },
      { command: "git switch -c feature", description: "Create and switch to a new branch" },
      { command: "git restore --staged file", description: "Unstage a file, keeping the changes" },
      { command: "git stash && git stash pop", description: "Shelve changes and bring them back" },
      { command: "git reset --hard origin/main", description: "Match local to remote, discarding local changes" },
      { command: "git clean -fd", description: "Delete untracked files and directories" },
    ],
  },
  {
    id: "ssh",
    title: "SSH and transfer",
    icon: ArrowRightLeft,
    commands: [
      { command: 'ssh-keygen -t ed25519 -C "you@example.com"', description: "Generate a modern SSH key pair" },
      { command: "ssh-copy-id user@host", description: "Install your public key on a server" },
      { command: "ssh -i key.pem user@host", description: "Connect using a specific private key" },
      { command: "scp file user@host:/path/", description: "Copy a file to a remote host" },
      { command: "scp -r dir user@host:/path/", description: "Copy a directory to a remote host" },
      { command: "ssh -L 5432:localhost:5432 user@host", description: "Forward a remote port to your machine" },
    ],
  },
];
