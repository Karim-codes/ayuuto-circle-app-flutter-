import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    ),
    LiquidGlassWidgets.initialize(),
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

    return MaterialApp.router(
      title: 'AyuutoCircle',
      debugShowCheckedModeBanner: false,
      theme: simpleMode ? AppTheme.simpleLightTheme : AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('so')],
      localizationsDelegates: [
        AppLocalizationsDelegate(locale.languageCode),
      ],
      routerConfig: router,
    );
  }
}
