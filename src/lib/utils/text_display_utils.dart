import 'dart:math' as math;

/// Shortens long emails for narrow UI (keeps @domain readable when possible).
/// Example: `jan.jansen@universiteit.nl` → `jan.jan…@universiteit.nl`
String truncateEmail(String email, {int maxLength = 30}) {
  final value = email.trim();
  if (value.isEmpty || value == '—') return value;
  if (value.length <= maxLength) return value;

  final at = value.indexOf('@');
  if (at <= 0 || at >= value.length - 1) {
    return '${value.substring(0, math.max(1, maxLength - 1))}…';
  }

  final local = value.substring(0, at);
  final domain = value.substring(at + 1);

  // Prefer showing most of the domain (often more recognizable).
  final domainMax = math.min(domain.length, (maxLength * 0.55).round().clamp(6, 18));
  final domainShown = domain.length > domainMax
      ? '${domain.substring(0, math.max(1, domainMax - 1))}…'
      : domain;

  final localMax = maxLength - domainShown.length - 1;
  if (localMax < 2) {
    return '${value.substring(0, math.max(1, maxLength - 1))}…';
  }

  final localShown = local.length > localMax
      ? '${local.substring(0, math.max(1, localMax - 1))}…'
      : local;

  return '$localShown@$domainShown';
}

