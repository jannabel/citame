import 'package:citapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Helper extension for easy access to localizations
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
