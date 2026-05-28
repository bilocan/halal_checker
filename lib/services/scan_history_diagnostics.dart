/// Last-known scan-history DB state for in-app support (no Mac/Xcode required).
class ScanHistoryDiagnostics {
  const ScanHistoryDiagnostics({
    this.databasePath,
    this.scanCount = 0,
    this.lastError,
    this.lastSuccessAt,
  });

  final String? databasePath;
  final int scanCount;
  final String? lastError;
  final DateTime? lastSuccessAt;

  bool get isHealthy => lastError == null;

  String toSupportText() {
    final buf = StringBuffer()
      ..writeln('Scan history diagnostics')
      ..writeln('path: ${databasePath ?? '(not opened)'}')
      ..writeln('scans: $scanCount')
      ..writeln('last OK: ${lastSuccessAt?.toIso8601String() ?? 'never'}');
    if (lastError != null) {
      buf.writeln('error: $lastError');
    }
    return buf.toString();
  }
}
