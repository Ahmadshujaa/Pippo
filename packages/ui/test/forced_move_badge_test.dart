import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/features/analysis/widgets/MoveClassificationUI.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forced badge loads from package assets with the green color',
      (tester) async {
    expect(MoveClassificationUI.getColor(MoveClassification.forced),
        MoveClassificationUI.getColor(MoveClassification.best));
    expect(MoveClassificationUI.getLabel(MoveClassification.forced), 'Forced');
    final asset = MoveClassificationUI.getAssetName(MoveClassification.forced);
    expect(asset, 'assets/classifications/Forced.png');
    await tester.pumpWidget(MaterialApp(
      home: Image.asset(asset, package: MoveClassificationUI.package),
    ));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Image));
      await precacheImage(
        AssetImage(asset, package: MoveClassificationUI.package),
        context,
        onError: (error, stack) => fail('Badge failed to load: $error'),
      );
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });
}
