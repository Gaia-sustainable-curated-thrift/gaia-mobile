import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaia_mobile/models/product.dart';
import 'package:gaia_mobile/pages/product_page.dart';
import 'package:gaia_mobile/services/product_api.dart';

class _FakeProductApi extends ProductApi {
  @override
  Future<List<Product>> fetchProducts() async => const [
        Product(
          id: 1,
          title: 'Vintage jacket',
          description: 'A lovely second-hand jacket.',
          price: 150000,
          condition: 'good',
          categoryName: 'Outerwear',
          sellerName: 'gaia-seller',
          imageUrl: null,
        ),
      ];
}

void main() {
  testWidgets('catalog loads API products and opens product detail',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProductPage(api: _FakeProductApi()))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vintage jacket'), findsOneWidget);
    expect(find.text('Rp150.000'), findsOneWidget);

    await tester.tap(find.text('Vintage jacket'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Produk'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('A lovely second-hand jacket.'), findsOneWidget);
    expect(find.text('Dijual oleh gaia-seller'), findsOneWidget);
  });

  testWidgets('catalog search filters products', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProductPage(api: _FakeProductApi()))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'not found');
    await tester.pumpAndSettle();

    expect(find.text('Produk tidak ditemukan.'), findsOneWidget);
  });
}
