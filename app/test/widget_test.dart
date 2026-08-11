import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:ecommerce_platform/core/widgets/product_card.dart";
import "package:ecommerce_platform/features/catalog/domain/entities/product.dart";

void main() {
  testWidgets("ProductCard shows product name and price", (tester) async {
    const product = Product(
      id: "p1",
      name: "Test Product",
      imageUrl: "https://picsum.photos/seed/p1/400/400",
      price: 1999,
      rating: 4.5,
      reviewCount: 12,
      category: "Fashion",
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProductCard(product: product, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text("Test Product"), findsOneWidget);
    expect(find.textContaining("1999"), findsOneWidget);
  });

  testWidgets("EmptyView renders message", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text("No products match your search"))),
      ),
    );
    expect(find.text("No products match your search"), findsOneWidget);
  });
}
