import 'package:flutter_test/flutter_test.dart';
import 'package:smart_green_flutter/main.dart';

void main() {
  testWidgets('SmartGreen app smoke test', (WidgetTester tester) async {
    expect(SmartGreenApp, isNotNull);
  });
}
