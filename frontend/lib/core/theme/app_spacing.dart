import '../constants/app_sizes.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = AppSizes.paddingXS;
  static const double xs = AppSizes.paddingSmall;
  static const double sm = 12;
  static const double md = AppSizes.paddingMedium;
  static const double lg = AppSizes.paddingLarge;
  static const double xl = AppSizes.paddingXL;
  static const double xxl = 40;

  static double pageHorizontal(double width) {
    if (width < 380) {
      return xs;
    }
    if (width >= 700) {
      return lg;
    }
    return md;
  }
}
