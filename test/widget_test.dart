import 'package:aergrow/app/aergrow_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app starts on the source selection', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AergRowApp()));

    expect(find.text('PM5 suchen'), findsOneWidget);
  });
}
