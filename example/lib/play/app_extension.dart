extension IntExtension on int {
  String toStringDigits(int num) {
    if (this == null) {
      return "";
    }
    num = num ?? 0;

    var str = '$this';
    for (var i = str.length; i < num; ++i) {
      str = '0$str';
    }
    return str;
  }
}

extension DateTimeExtension on DateTime {
  String toShortString() {
    if (this == null) {
      return "";
    }
    return toString().substring(0, 19);
  }
}

extension StringExtension on String {
  bool checkLength(int min, int max) {
    if (isEmpty) return false;
    if (length >= min && length <= max) {
      return true;
    }
    return false;
  }
}
