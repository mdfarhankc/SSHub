import 'package:pigeon/pigeon.dart';

// Edit here, then run `make pigeon`. Both sides are generated.
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/security/secure_platform.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/mdfarhankc/sshub/SecurePlatformApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.mdfarhankc.sshub'),
    dartPackageName: 'sshub',
  ),
)
@HostApi()
abstract class SecurePlatformApi {
  // Hides the app from screenshots and the recents preview.
  void setBlockScreenshots(bool enabled);

  // Flags the clip sensitive so keyboards do not preview it.
  void copySensitive(String text);
}
