import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    ),
    LiquidGlassWidgets.initialize(),
    NotificationService().init(),
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: AyuutoCircleApp()));
}

class AyuutoCircleApp extends ConsumerWidget {
  const AyuutoCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final simpleMode = ref.watch(simpleModeProvider);

    // Somali ('so') isn't supported by Flutter's Material/Cupertino
    // localizations, so we always tell Flutter the locale is 'en' for
    // those delegates. Our own AppLocalizations handles the real language.
    return MaterialApp.router(
      title: 'AyuutoCircle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: [
        AppLocalizationsDelegate(locale.languageCode),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        // Simple mode: scale ALL text up by 1.25× so the difference
        // is visible even on hardcoded font sizes.
        if (simpleMode) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.25),
            ),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}
