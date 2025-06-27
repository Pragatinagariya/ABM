
import 'package:ABM2/shared_pref_helper.dart';
import 'package:ABM2/utils/logger_util.dart';
import 'package:flutter/material.dart';


class Application {
  static final Application _application = Application._internal();

  factory Application() {
    return _application;
  }

  Application._internal();

  final List<String> supportedLanguages = [
    "English",
    "ગુજરાતી" /*,"Spanish"*/
  ];

  //where es=spanish
  final List<String> supportedLanguagesCodes = ["en", "gu"];



  ///tmp language after post login
  static bool tmpLanguage = false;



  //returns the list of supported Locales
  Iterable<Locale> supportedLocales() =>
      supportedLanguagesCodes.map<Locale>((language) => Locale(language, 'IN'));

  //function to be invoked when changing the language
  LocaleChangeCallback? onLocaleChanged;
  
  get pref_app_lang_code => null;
  
  get pref_app_lang_country => null;

  getLocale() async {
    String? languageCode =
    SharedPrefHelper.instance.getStringValue(pref_app_lang_code);

    if (languageCode!.isEmpty) {
      languageCode = 'en'; // English
      SharedPrefHelper.instance.setValue(pref_app_lang_code, languageCode);
    }

    String? languageCountry = SharedPrefHelper.instance.getStringValue(pref_app_lang_country);
    if (languageCountry!.isEmpty) {
      languageCountry = 'IN';
      SharedPrefHelper.instance.setValue(pref_app_lang_country, languageCountry);


    }
    Logger.get().log("MyApp Locale : ${languageCode}_$languageCountry");

    return Locale(languageCode, languageCountry);
  }




}

Application application = Application();

typedef LocaleChangeCallback = void Function(Locale locale);
