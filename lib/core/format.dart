/// Groups the digits of [intPart] with [separator] every 3 digits from the
/// right — e.g. groupThousands('1234567', ' ') -> '1 234 567'.
String _groupThousands(String intPart, String separator) {
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return (negative ? '-' : '') + buffer.toString();
}

/// so'm / generic numbers — space-grouped, matching the Webapp's
/// `new Intl.NumberFormat('uz-UZ')` output (e.g. 1 234 567).
String formatMoney(num value) => _groupThousands(value.round().toString(), ' ');

/// USD balances — always comma-grouped with a leading `$`, matching the
/// Webapp's `usd()` helper. Investment balances are always denominated in
/// USD across the whole platform, never so'm.
String formatUsd(num value) {
  final rounded = double.parse(value.toStringAsFixed(2));
  final isWhole = rounded == rounded.roundToDouble();
  if (isWhole) {
    return '\$${_groupThousands(rounded.toInt().toString(), ',')}';
  }
  final parts = rounded.toStringAsFixed(2).split('.');
  return '\$${_groupThousands(parts[0], ',')}.${parts[1]}';
}
