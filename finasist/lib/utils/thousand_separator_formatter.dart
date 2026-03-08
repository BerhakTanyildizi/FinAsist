import 'package:flutter/services.dart';

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digitsOnly = newValue.text.replaceAll('.', '').replaceAll(',', '');

    if (digitsOnly.isEmpty) return const TextEditingValue();

    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) return oldValue;

    final formatted = _addSeparators(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addSeparators(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
