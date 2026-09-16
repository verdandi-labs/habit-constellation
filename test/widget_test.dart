import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.byType(MainNavigation), findsOneWidget);
  });
}
