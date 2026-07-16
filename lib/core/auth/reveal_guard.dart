import 'package:flutter/widgets.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/di/service_locator.dart';

extension RevealGuard on BuildContext {
  // Authorises revealing a stored secret: prompts for auth only when locked.
  Future<bool> confirmReveal({required bool locked, required String reason}) {
    if (!locked) return Future.value(true);
    return sl<LocalAuthService>().authenticate(reason);
  }
}
