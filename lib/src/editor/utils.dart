import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../model/board.dart';

const String nullUnicode = '\u0000';

extension TextNodeTypeExtension on BoardTextType {
  TextStyle get textStyle => styleForButton(this);
  EdgeInsets get textPadding => paddingForButton(this);

  EdgeInsets get padding {
    return EdgeInsets.zero;
  }
}

TextStyle styleForButton(BoardTextType type) {
  switch (type) {
    case BoardTextType.heading1:
      return const TextStyle(
        fontFamily: 'Work Sans',
        color: Color(0xff353535),
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1 + (1 / 12),
      );
    case BoardTextType.heading2:
      return const TextStyle(
        fontFamily: 'Work Sans',
        color: Color(0xff353535),
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1 + (1 / 5),
        letterSpacing: 0.18,
      );
    case BoardTextType.heading3:
      return const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xff4C4C4C),
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1 + (3 / 7),
        letterSpacing: 0.15,
      );
    case BoardTextType.body1:
      return const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xff898989),
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1 + (3 / 7),
        letterSpacing: 0.15,
      );
    default:
      return const TextStyle();
  }
}

EdgeInsets paddingForButton(BoardTextType type) {
  switch (type) {
    case BoardTextType.heading1:
      return const EdgeInsets.symmetric(vertical: 8);
    case BoardTextType.heading2:
      return const EdgeInsets.symmetric(vertical: 8);
    case BoardTextType.heading3:
      return const EdgeInsets.symmetric(vertical: 8);
    case BoardTextType.body1:
      return const EdgeInsets.symmetric(vertical: 0);
    default:
      return EdgeInsets.zero;
  }
}

class FirstLetterUpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String s = newValue.text;
    String upperCasedString = s;
    if (s.length > 1 && s[1].toUpperCase() != s[1] && s.startsWith(nullUnicode)) {
      upperCasedString = '${s[0]}${s[1].toUpperCase()}${s.substring(2)}';
    }
    return TextEditingValue(
      text: upperCasedString,
      selection: newValue.selection,
    );
  }
}
