import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/main.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login screen loads test', (WidgetTester tester) async {
    // Pass LoginScreen as the homeWidget to fix the constructor error
    await tester.pumpWidget(const MyApp(homeWidget: LoginScreen()));

    // Verify that the login screen elements are present
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
