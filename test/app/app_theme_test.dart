import 'package:aergrow/app/aergrow_app.dart';
import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app uses the dark theme built from the tokens of design D1.
void main() {
  testWidgets('the app uses the dark theme with the colours and fonts of D1', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(const RowerChoice.simulator()))],
      child: const AergRowApp(),
    ));

    final theme = Theme.of(tester.element(find.byType(StartScreen)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.bg);
    expect(theme.colorScheme.primary, AppColors.zoneIn);
    expect(theme.filledButtonTheme.style?.backgroundColor?.resolve({}), AppColors.zoneIn);
    expect(theme.colorScheme.onSurface, AppColors.text);
    expect(theme.colorScheme.onSurfaceVariant, AppColors.textMuted);
    expect(theme.colorScheme.error, AppColors.zoneOut);
    expect(theme.cardTheme.color, AppColors.surface);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.text);
    expect(theme.textTheme.titleLarge?.fontFamily, AppFonts.text);
    expect(theme.textTheme.displayLarge?.fontFamily, AppFonts.display);
    expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w700);
    expect(theme.textTheme.headlineMedium?.fontFamily, AppFonts.display);
  });
}
