import 'package:flutter_test/flutter_test.dart';

import 'package:snapcircle/app.dart';

void main() {
  testWidgets('SnapCircle app renders splash screen', (tester) async {
    await tester.pumpWidget(const SnapCircleApp());

    expect(find.text('SnapCircle'), findsOneWidget);
  });
}
