import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fftcg_companion/widgets/card_tile.dart';
import 'package:fftcg_companion/models/card.dart' as card_model;
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForTesting();
  });

  group('CardTile Widget Tests', () {
    late card_model.Card testCard;

    setUp(() {
      testCard = card_model.Card(
        id: 'test-id',
        name: 'Test Card',
        cleanName: 'test card',
        elements: ['Fire'],
        type: 'Forward',
        cost: 3,
        power: '5000',
        rarity: 'R',
        setId: 'TEST',
        setNumber: '001',
        text: 'Test card text',
        imageUrls: card_model.CardImageUrls(
          small: 'small_url',
          normal: 'normal_url',
          large: 'large_url',
        ),
        lastUpdated: DateTime.now(),
      );
    });

    testWidgets('CardTile displays card information correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CardTile(
            card: testCard,
            onTap: () {},
            isTest: true,
          ),
        ),
      ));

      await tester.pump();
      expect(find.text('Test Card'), findsOneWidget);
      expect(find.text('Forward • 001'), findsOneWidget);
      expect(find.text('Cost: 3'), findsOneWidget);
    });

    testWidgets('CardTile onTap callback works', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CardTile(
            card: testCard,
            onTap: () {
              tapped = true;
            },
            isTest: true,
          ),
        ),
      ));

      await tester.pump();
      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });
  });
}
