import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled fonts and their licence files (SIL Open Font License).
const fontLicenses = {
  'Barlow Condensed': 'assets/fonts/BarlowCondensed/OFL.txt',
  'Barlow': 'assets/fonts/Barlow/OFL.txt',
  'IBM Plex Sans': 'assets/fonts/IBMPlexSans/OFL.txt',
};

/// Adds the licences of the bundled fonts to the licence page, as the OFL
/// asks for its text to travel with the fonts.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: asset) in fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString(asset));
    }
  });
}
