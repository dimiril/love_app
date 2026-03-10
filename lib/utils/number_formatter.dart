class NumberFormatter {
  static String format(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      double result = number / 1000.0;
      // إذا كان الرقم بدون كسور (مثلاً 1.0k) نظهره كـ 1k
      return result % 1 == 0 
          ? "${result.toInt()}k" 
          : "${result.toStringAsFixed(1)}k";
    } else {
      double result = number / 1000000.0;
      return result % 1 == 0 
          ? "${result.toInt()}M" 
          : "${result.toStringAsFixed(1)}M";
    }
  }
}
