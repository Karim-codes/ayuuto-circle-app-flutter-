import 'package:flutter/widgets.dart';
import 'app_en.dart';
import 'app_so.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations('en');
  }

  Map<String, String> get _strings {
    switch (languageCode) {
      case 'so':
        return so;
      case 'en':
      default:
        return en;
    }
  }

  String get(String key) => _strings[key] ?? en[key] ?? key;

  String format(String key, Map<String, String> params) {
    var result = get(key);
    params.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    return result;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String languageCode;

  const AppLocalizationsDelegate(this.languageCode);

  @override
  bool isSupported(Locale locale) => ['en', 'so'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(languageCode);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) =>
      old.languageCode != languageCode;
}
