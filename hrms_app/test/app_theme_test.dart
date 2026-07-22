import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/theme/app_theme.dart';

void main() {
  test(
    'AppColors.darkCard matches the dark summary-card color used across screens',
    () {
      expect(AppColors.darkCard.toARGB32(), equals(0xFF0F172A));
    },
  );
}
