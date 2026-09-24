// A point-in-time snapshot of a server's resource use, gathered over SSH.
class ServerStats {
  final String hostname;
  final String os;
  final String kernel;
  final int uptimeSeconds;
  final int cores;

  // 1, 5 and 15 minute load averages.
  final double load1;
  final double load5;
  final double load15;

  // Whole-CPU busy percentage, null until two samples have been compared.
  final double? cpuPercent;

  // Memory and swap in bytes.
  final int memTotal;
  final int memUsed;
  final int swapTotal;
  final int swapUsed;

  final List<DiskUsage> disks;
  final GpuUsage? gpu;

  // The heaviest processes by CPU, so a spike can be traced to what caused it.
  final List<ProcessInfo> processes;

  const ServerStats({
    required this.hostname,
    required this.os,
    required this.kernel,
    required this.uptimeSeconds,
    required this.cores,
    required this.load1,
    required this.load5,
    required this.load15,
    required this.cpuPercent,
    required this.memTotal,
    required this.memUsed,
    required this.swapTotal,
    required this.swapUsed,
    required this.disks,
    required this.gpu,
    required this.processes,
  });

  double get memFraction => memTotal <= 0 ? 0 : memUsed / memTotal;
  double get swapFraction => swapTotal <= 0 ? 0 : swapUsed / swapTotal;
}

class DiskUsage {
  final String mount;
  final int total;
  final int used;
  const DiskUsage({required this.mount, required this.total, required this.used});

  double get fraction => total <= 0 ? 0 : used / total;
}

class ProcessInfo {
  final int pid;
  final String command;
  final double cpuPercent;
  final double memPercent;
  // Resident memory in KB; only the full process list fetches it.
  final int? rssKb;
  const ProcessInfo({
    required this.pid,
    required this.command,
    required this.cpuPercent,
    required this.memPercent,
    this.rssKb,
  });
}

class GpuUsage {
  final int utilPercent;
  final int memUsedMb;
  final int memTotalMb;
  const GpuUsage({
    required this.utilPercent,
    required this.memUsedMb,
    required this.memTotalMb,
  });

  double get memFraction => memTotalMb <= 0 ? 0 : memUsedMb / memTotalMb;
}
