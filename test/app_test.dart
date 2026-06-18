import 'package:awe_pay/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders system admin sign in screen', (tester) async {
    await tester.pumpWidget(const AwePayApp());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
