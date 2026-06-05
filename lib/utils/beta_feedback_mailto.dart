import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

const betaFeedbackEmail = 'bilalgunay@gmail.com';

/// Prefilled mailto for closed-test feedback (version + platform in subject/body).
Future<Uri> buildBetaFeedbackMailto({PackageInfo? packageInfo}) async {
  final info = packageInfo ?? await PackageInfo.fromPlatform();
  final subject = Uri.encodeComponent(
    'HalalScan Beta v${info.version} (build ${info.buildNumber})',
  );
  final body = Uri.encodeComponent(
    'Device: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
    'App: v${info.version} (${info.buildNumber})\n\n'
    'What I tested:\n'
    '- \n\n'
    'Issue or suggestion:\n'
    '- \n',
  );
  return Uri.parse('mailto:$betaFeedbackEmail?subject=$subject&body=$body');
}
