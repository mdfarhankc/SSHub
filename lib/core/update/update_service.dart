import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String notes;
  final String url;
  final bool updateAvailable;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.notes,
    required this.url,
    required this.updateAvailable,
  });
}

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
}

class UpdateService {
  static const _repo = "mdfarhankc/SSHub";
  static const _releasesUrl = "https://github.com/$_repo/releases/latest";

  Future<UpdateInfo> check() async {
    final current = (await PackageInfo.fromPlatform()).version;

    final http.Response res;
    try {
      res = await http.get(
        Uri.parse("https://api.github.com/repos/$_repo/releases/latest"),
        // GitHub rejects requests without a User-Agent.
        headers: const {
          "Accept": "application/vnd.github+json",
          "User-Agent": "SSHub",
        },
      );
    } catch (_) {
      throw const UpdateException("No internet connection.");
    }

    if (res.statusCode == 404) {
      throw const UpdateException("No releases published yet.");
    }
    if (res.statusCode != 200) {
      throw const UpdateException("Could not reach the update server.");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final latest = ((json['tag_name'] as String?) ?? "").replaceFirst(
      RegExp(r'^v'),
      '',
    );

    return UpdateInfo(
      currentVersion: current,
      latestVersion: latest.isEmpty ? current : latest,
      notes: ((json['body'] as String?) ?? "").trim(),
      url: (json['html_url'] as String?) ?? _releasesUrl,
      updateAvailable: _isNewer(latest, current),
    );
  }

  bool _isNewer(String latest, String current) {
    List<int> parts(String v) =>
        v.split('-').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parts(latest);
    final b = parts(current);
    for (var i = 0; i < a.length || i < b.length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
