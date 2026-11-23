import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/data/config/app_color.dart';
import 'app/data/config/functions/dio_function/app_config.dart';
import 'app/data/services/app_translations.dart';
import 'app/data/services/app_update_service.dart';
import 'app/data/services/deep_link_service.dart';
import 'app/data/services/recently_viewed_service.dart';
import 'app/data/services/rewards_service.dart';
import 'app/data/services/wallet_pin_service.dart';
import 'app/data/services/wishlist_service.dart';
import 'app/modules/splash/bindings/splash_binding.dart';
import 'app/modules/splash/views/splash_view.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const envFile = String.fromEnvironment('ENV_FILE', defaultValue: '');
  const envName = String.fromEnvironment('ENV', defaultValue: '');

  String primaryEnv = '.env';
  if (envFile.isNotEmpty) {
    primaryEnv = envFile;
  } else if (envName.isNotEmpty) {
    primaryEnv = '.env.$envName';
  } else if (kReleaseMode) {
    primaryEnv = '.env.production';
  }

  bool loaded = false;
  try {
    await dotenv.load(fileName: primaryEnv);
    loaded = true;
  } catch (_) {}

  if (!loaded) {
    for (final candidate in ['.env', '.env.local', '.env.production']) {
      try {
        await dotenv.load(fileName: candidate);
        loaded = true;
        break;
      } catch (_) {}
    }
  }

  initAppConfig();
  await GetStorage.init();
  Get.put(RewardsService(), permanent: true);
  Get.put(RecentlyViewedService(), permanent: true);
  Get.put(WalletPinService(), permanent: true);
  Get.put(WishlistService(), permanent: true);
  Get.put(DeepLinkService(), permanent: true);
  Get.put(AppUpdateService(), permanent: true);
  DeepLinkService.to.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: "ALIF",
          translations: AppTranslations(),
          locale: AppTranslations.currentLocale,
          fallbackLocale: const Locale('en', 'US'),
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColor.background,
            textTheme: GoogleFonts.latoTextTheme(),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColor.primary,
              primary: AppColor.primary,
            ),
          ),
          initialRoute: AppPages.INITIAL,
          unknownRoute: GetPage(
            name: '/notfound',
            page: () => const SplashView(),
            binding: SplashBinding(),
          ),
          getPages: AppPages.routes,
        );
      },
    ),
  );
}
