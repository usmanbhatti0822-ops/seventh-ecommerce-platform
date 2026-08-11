import "dart:math";
import "package:dio/dio.dart";

/// Thrown by route handlers to produce a realistic HTTP error response
/// (caught by the ApiClient interceptor and turned into a DioException so
/// every repository's existing `catch (DioException e)` / ApiFailure path
/// works identically to talking to a real server).
class MockApiException implements Exception {
  final int statusCode;
  final String message;
  MockApiException(this.statusCode, this.message);
}

/// In-process fake backend for the "Seventh" storefront demo.
///
/// This is the single source of truth for demo-mode data. It is intentionally
/// shaped like a real REST API (JSON in/out, status codes, realistic latency)
/// so the app's repository/provider layers are written exactly as they would
/// be against the real NestJS backend — flipping `AppConfig.demoMode` to
/// false is the only thing that changes.
///
/// State is in-memory and resets on app restart, which is expected for a demo.
class MockBackend {
  MockBackend._() {
    _seed();
  }
  static final MockBackend instance = MockBackend._();

  final _rand = Random();
  static const _demoOtp = "1234";

  late List<Map<String, dynamic>> _products;
  late List<Map<String, dynamic>> _categories;
  final List<Map<String, dynamic>> _cart = [];
  late List<Map<String, dynamic>> _orders;
  late List<Map<String, dynamic>> _notifications;
  late Map<String, List<Map<String, dynamic>>> _reviews;
  final Set<String> _wishlist = {};
  late List<Map<String, dynamic>> _coupons;
  late List<Map<String, dynamic>> _addresses;
  late List<Map<String, dynamic>> _customers;
  late List<Map<String, dynamic>> _staff;
  late List<Map<String, dynamic>> _suppliers;
  late List<Map<String, dynamic>> _inventory;
  int _cartSeq = 1;
  int _orderSeq = 1006;
  int _reviewSeq = 1;
  int _notifSeq = 100;

  // ---------------------------------------------------------------------
  // Public entry point used by ApiClient's demo interceptor.
  // ---------------------------------------------------------------------
  Future<Response<dynamic>> handle(RequestOptions o) async {
    await Future.delayed(Duration(milliseconds: 280 + _rand.nextInt(370)));
    final segs = o.path.split("/").where((s) => s.isNotEmpty).toList();
    final method = o.method.toUpperCase();
    final data = _route(method, segs, o);
    return Response(requestOptions: o, statusCode: 200, data: data);
  }

  dynamic _route(String m, List<String> s, RequestOptions o) {
    // ---- auth ----
    if (s.length == 3 && s[0] == "auth" && s[1] == "otp" && s[2] == "request" && m == "POST") {
      final phone = (o.data as Map)["phone"]?.toString() ?? "";
      if (phone.isEmpty) throw MockApiException(400, "Phone number is required");
      return {"devCode": _demoOtp, "message": "Demo mode: use code $_demoOtp to verify"};
    }
    if (s.length == 3 && s[0] == "auth" && s[1] == "otp" && s[2] == "verify" && m == "POST") {
      final code = (o.data as Map)["code"]?.toString() ?? "";
      if (code != _demoOtp) throw MockApiException(400, "Invalid OTP — use the demo code $_demoOtp");
      return {"accessToken": "demo-jwt-token", "user": _demoUser};
    }
    if (s.length == 2 && s[0] == "auth" && s[1] == "social" && m == "POST") {
      return {"accessToken": "demo-jwt-token", "user": _demoUser};
    }

    // ---- categories ----
    if (s.length == 1 && s[0] == "categories" && m == "GET") return _categories;

    // ---- products ----
    if (s.length == 1 && s[0] == "products" && m == "GET") {
      final q = o.queryParameters;
      var list = _products;
      final search = q["search"]?.toString().toLowerCase();
      final categoryId = q["categoryId"]?.toString();
      if (search != null && search.isNotEmpty) {
        list = list.where((p) => (p["name"] as String).toLowerCase().contains(search)).toList();
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        list = list.where((p) => p["category"]["id"] == categoryId).toList();
      }
      return list;
    }
    if (s.length == 2 && s[0] == "products" && m == "GET") {
      return _findProduct(s[1]);
    }
    if (s.length == 1 && s[0] == "products" && m == "POST") {
      final body = Map<String, dynamic>.from(o.data as Map);
      final id = "p${_products.length + 1}";
      final categoryId = body["categoryId"]?.toString();
      final category = _categories.firstWhere((c) => c["id"] == categoryId, orElse: () => _categories.first);
      final product = {
        "id": id,
        "name": body["name"] ?? "Untitled Product",
        "basePrice": body["basePrice"] ?? 0,
        "oldPrice": body["oldPrice"],
        "images": (body["images"] as List?) ?? ["https://picsum.photos/seed/sw-$id-a/900/1100"],
        "category": category,
        "variants": (body["variants"] as List?) ?? [],
        "rating": 0.0,
        "reviewCount": 0,
        "badge": body["badge"],
        "description": body["description"] ?? "",
      };
      _products.add(product);
      return product;
    }
    if (s.length == 2 && s[0] == "products" && m == "PATCH") {
      final product = _findProduct(s[1]);
      (o.data as Map).forEach((k, v) => product[k] = v);
      return product;
    }
    if (s.length == 2 && s[0] == "products" && m == "DELETE") {
      _products.removeWhere((p) => p["id"] == s[1]);
      return {"success": true};
    }
    if (s.length == 2 && s[0] == "products" && s[1] == "import" && m == "POST") {
      final rows = (o.data as List).cast<Map>();
      var imported = 0;
      for (final row in rows) {
        final id = "p${_products.length + 1}";
        _products.add({
          "id": id,
          "name": row["name"] ?? "Untitled Product",
          "basePrice": row["basePrice"] ?? 0,
          "oldPrice": null,
          "images": ["https://picsum.photos/seed/sw-$id-a/900/1100"],
          "category": _categories.first,
          "variants": [],
          "rating": 0.0,
          "reviewCount": 0,
          "badge": null,
          "description": row["description"] ?? "",
        });
        imported++;
      }
      return {"imported": imported};
    }

    // ---- cart ----
    if (s.length == 1 && s[0] == "cart" && m == "GET") return {"items": _cart};
    if (s.length == 2 && s[0] == "cart" && s[1] == "items" && m == "POST") {
      final body = o.data as Map;
      final variantId = body["variantId"]?.toString() ?? "";
      final qty = (body["qty"] as num?)?.toInt() ?? 1;
      _addToCart(variantId, qty);
      return {"items": _cart};
    }
    if (s.length == 3 && s[0] == "cart" && s[1] == "items" && m == "PATCH") {
      final qty = ((o.data as Map)["qty"] as num?)?.toInt() ?? 1;
      final line = _cart.firstWhere((c) => c["id"] == s[2], orElse: () => throw MockApiException(404, "Cart item not found"));
      if (qty <= 0) {
        _cart.remove(line);
      } else {
        line["qty"] = qty;
      }
      return {"items": _cart};
    }
    if (s.length == 3 && s[0] == "cart" && s[1] == "items" && m == "DELETE") {
      _cart.removeWhere((c) => c["id"] == s[2]);
      return {"items": _cart};
    }

    // ---- addresses ----
    if (s.length == 1 && s[0] == "addresses" && m == "GET") return _addresses;
    if (s.length == 1 && s[0] == "addresses" && m == "POST") {
      final body = Map<String, dynamic>.from(o.data as Map);
      body["id"] = "addr-${_addresses.length + 1}";
      _addresses.add(body);
      return body;
    }

    // ---- wishlist ----
    if (s.length == 1 && s[0] == "wishlist" && m == "GET") {
      return _products.where((p) => _wishlist.contains(p["id"])).toList();
    }
    if (s.length == 2 && s[0] == "wishlist" && m == "POST") {
      _wishlist.add(s[1]);
      return {"productIds": _wishlist.toList()};
    }
    if (s.length == 2 && s[0] == "wishlist" && m == "DELETE") {
      _wishlist.remove(s[1]);
      return {"productIds": _wishlist.toList()};
    }

    // ---- orders ----
    if (s.length == 1 && s[0] == "orders" && m == "GET") return _orders;
    if (s.length == 1 && s[0] == "orders" && m == "POST") return _placeOrder(o.data as Map);
    if (s.length == 2 && s[0] == "orders" && m == "GET") {
      return _orders.firstWhere((ord) => ord["id"] == s[1], orElse: () => throw MockApiException(404, "Order not found"));
    }
    if (s.length == 3 && s[0] == "orders" && s[2] == "cancel" && m == "PATCH") {
      final order = _orders.firstWhere((ord) => ord["id"] == s[1], orElse: () => throw MockApiException(404, "Order not found"));
      order["status"] = "cancelled";
      return order;
    }
    if (s.length == 3 && s[0] == "orders" && s[2] == "status" && m == "PATCH") {
      final order = _orders.firstWhere((ord) => ord["id"] == s[1], orElse: () => throw MockApiException(404, "Order not found"));
      final status = (o.data as Map)["status"]?.toString();
      const valid = ["placed", "confirmed", "shipped", "out_for_delivery", "delivered", "cancelled"];
      if (status == null || !valid.contains(status)) throw MockApiException(400, "Invalid status");
      order["status"] = status;
      (order["timeline"] as List).add({"stage": status, "at": DateTime.now().toIso8601String()});
      return order;
    }

    // ---- notifications ----
    if (s.length == 1 && s[0] == "notifications" && m == "GET") return _notifications;
    if (s.length == 3 && s[0] == "notifications" && s[2] == "read" && m == "PATCH") {
      final n = _notifications.firstWhere((n) => n["id"] == s[1], orElse: () => throw MockApiException(404, "Notification not found"));
      n["read"] = true;
      return n;
    }

    // ---- reviews ----
    if (s.length == 1 && s[0] == "reviews" && m == "GET") {
      final productId = o.queryParameters["productId"]?.toString();
      if (productId == null) return _reviews.values.expand((v) => v).toList();
      return _reviews[productId] ?? [];
    }
    if (s.length == 1 && s[0] == "reviews" && m == "POST") return _addReview(o.data as Map);

    // ---- promotions ----
    if (s.length == 1 && s[0] == "promotions" && m == "GET") return _coupons;

    // ---- admin ----
    if (s.length == 2 && s[0] == "admin" && s[1] == "dashboard" && m == "GET") return _dashboard();
    if (s.length == 2 && s[0] == "admin" && s[1] == "orders" && m == "GET") return _orders;
    if (s.length == 2 && s[0] == "admin" && s[1] == "products" && m == "GET") return _products;
    if (s.length == 2 && s[0] == "admin" && s[1] == "customers" && m == "GET") return _customers;
    if (s.length == 2 && s[0] == "admin" && s[1] == "promotions" && m == "GET") return _coupons;
    if (s.length == 2 && s[0] == "admin" && s[1] == "reports" && m == "GET") return _reports();
    if (s.length == 2 && s[0] == "admin" && s[1] == "suppliers" && m == "GET") return _suppliers;
    if (s.length == 2 && s[0] == "admin" && s[1] == "inventory" && m == "GET") return _inventory;
    if (s.length == 2 && s[0] == "admin" && s[1] == "staff" && m == "GET") return _staff;

    throw MockApiException(404, "No mock route for $m /${s.join('/')}");
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Map<String, dynamic> get _demoUser => {
        "id": "u-demo",
        "name": "Usman Tariq",
        "email": "usman@example.com",
        "phone": "+923001234567",
      };

  Map<String, dynamic> _findProduct(String id) =>
      _products.firstWhere((p) => p["id"] == id, orElse: () => throw MockApiException(404, "Product not found"));

  ({Map<String, dynamic> product, Map<String, dynamic> variant}) _findVariant(String variantId) {
    for (final p in _products) {
      for (final v in (p["variants"] as List)) {
        if (v["id"] == variantId) return (product: p, variant: v as Map<String, dynamic>);
      }
    }
    throw MockApiException(404, "Variant not found");
  }

  void _addToCart(String variantId, int qty) {
    final found = _findVariant(variantId);
    if ((found.variant["stockQty"] as int) < qty) {
      throw MockApiException(400, "Only ${found.variant["stockQty"]} left in stock");
    }
    final existing = _cart.where((c) => c["variantId"] == variantId).toList();
    if (existing.isNotEmpty) {
      existing.first["qty"] = (existing.first["qty"] as int) + qty;
      return;
    }
    _cart.add({
      "id": "line-${_cartSeq++}",
      "productId": found.product["id"],
      "variantId": variantId,
      "name": found.product["name"],
      "imageUrl": (found.product["images"] as List).first,
      "price": found.variant["price"] ?? found.product["basePrice"],
      "size": found.variant["size"],
      "color": found.variant["color"],
      "qty": qty,
    });
  }

  double get _cartSubtotal => _cart.fold(0.0, (sum, c) => sum + (c["price"] as num) * (c["qty"] as int));

  Map<String, dynamic> _placeOrder(Map body) {
    if (_cart.isEmpty) throw MockApiException(400, "Your cart is empty");
    final addressId = body["addressId"]?.toString();
    final address = _addresses.firstWhere(
      (a) => a["id"] == addressId,
      orElse: () => throw MockApiException(400, "Select a delivery address"),
    );
    final paymentMethod = body["paymentMethod"]?.toString() ?? "COD";
    final couponCode = body["couponCode"]?.toString();
    final subtotal = _cartSubtotal;
    final shipping = subtotal >= 5000 ? 0.0 : 200.0;
    double discount = 0;
    if (couponCode != null && couponCode.isNotEmpty) {
      final coupon = _coupons.firstWhere((c) => c["code"] == couponCode, orElse: () => {});
      if (coupon.isNotEmpty) {
        discount = coupon["discountType"] == "percentage"
            ? subtotal * (coupon["discountValue"] as num) / 100
            : (coupon["discountValue"] as num).toDouble();
      }
    }
    final total = (subtotal + shipping - discount).clamp(0, double.infinity);
    final order = {
      "id": "ord-${_orderSeq}",
      "orderNumber": "SVN-${_orderSeq++}",
      "status": "placed",
      "createdAt": DateTime.now().toIso8601String(),
      "items": _cart.map((c) => Map<String, dynamic>.from(c)).toList(),
      "subtotal": subtotal,
      "shipping": shipping,
      "discount": discount,
      "total": total,
      "paymentMethod": paymentMethod,
      "paymentStatus": paymentMethod == "COD" ? "pending" : "paid",
      "address": address,
      "timeline": [
        {"stage": "Placed", "at": DateTime.now().toIso8601String()},
      ],
    };
    _orders.insert(0, order);
    _cart.clear();
    _notifications.insert(0, {
      "id": "n-${_notifSeq++}",
      "title": "Order Placed",
      "body": "Your order ${order["orderNumber"]} has been placed successfully.",
      "type": "order",
      "read": false,
      "createdAt": DateTime.now().toIso8601String(),
    });
    return order;
  }

  Map<String, dynamic> _addReview(Map body) {
    final productId = body["productId"]?.toString() ?? "";
    final rating = (body["rating"] as num?)?.toDouble() ?? 0;
    if (rating < 1 || rating > 5) throw MockApiException(400, "Rating must be between 1 and 5");
    final review = {
      "id": "rev-${_reviewSeq++}",
      "userName": "You",
      "rating": rating,
      "comment": body["comment"]?.toString() ?? "",
      "images": (body["images"] as List?) ?? [],
      "verified": true,
      "createdAt": DateTime.now().toIso8601String(),
    };
    _reviews.putIfAbsent(productId, () => []).insert(0, review);
    final product = _products.where((p) => p["id"] == productId);
    if (product.isNotEmpty) {
      final list = _reviews[productId]!;
      product.first["reviewCount"] = list.length;
      product.first["rating"] = list.fold(0.0, (s, r) => s + (r["rating"] as num)) / list.length;
    }
    return review;
  }

  Map<String, dynamic> _dashboard() {
    final totalRevenue = _orders.fold(0.0, (s, o) => s + (o["total"] as num));
    return {
      "revenue": totalRevenue,
      "revenueChangePct": 12.4,
      "orders": _orders.length,
      "ordersChangePct": 8.1,
      "customers": _customers.length,
      "customersChangePct": 5.6,
      "products": _products.length,
      "aov": _orders.isEmpty ? 0 : totalRevenue / _orders.length,
      "conversionRate": 3.8,
      "salesTrend": List.generate(14, (i) {
        final date = DateTime.now().subtract(Duration(days: 13 - i));
        return {
          "date": date.toIso8601String().substring(0, 10),
          "revenue": 18000 + _rand.nextInt(42000) + (i * 900),
        };
      }),
      "orderStatusBreakdown": [
        {"status": "Delivered", "count": 62},
        {"status": "Shipped", "count": 14},
        {"status": "Confirmed", "count": 9},
        {"status": "Placed", "count": 6},
        {"status": "Cancelled", "count": 4},
      ],
      "topProducts": _products.take(5).map((p) => {
            "id": p["id"],
            "name": p["name"],
            "image": (p["images"] as List).first,
            "unitsSold": 40 + _rand.nextInt(160),
            "revenue": (p["basePrice"] as num) * (40 + _rand.nextInt(160)),
          }).toList(),
      "lowStock": _inventory.where((i) => (i["stockQty"] as int) <= (i["lowStockThreshold"] as int)).toList(),
      "recentOrders": _orders.take(6).toList(),
      "recentActivity": [
        {"text": "New order ${_orders.isNotEmpty ? _orders.first["orderNumber"] : "SVN-1006"} placed", "at": "2 min ago"},
        {"text": "Ayesha Khan left a 5-star review on V2 Hoodie — Cloud", "at": "18 min ago"},
        {"text": "Low stock alert: Cargo Pant — Olive (S)", "at": "1 hr ago"},
        {"text": "Supplier 'Lahore Textile Co.' synced 240 SKUs", "at": "3 hr ago"},
        {"text": "Coupon FLASH500 used 12 times today", "at": "5 hr ago"},
      ],
    };
  }

  Map<String, dynamic> _reports() {
    return {
      "salesByCategory": _categories.map((c) {
        final catProducts = _products.where((p) => p["category"]["id"] == c["id"]);
        return {"category": c["name"], "revenue": 30000 + _rand.nextInt(180000), "unitsSold": 20 + _rand.nextInt(200), "productCount": catProducts.length};
      }).toList(),
      "supplierPerformance": _suppliers.map((s) => {
            "supplier": s["name"],
            "fulfillmentRate": s["fulfillmentRate"],
            "avgDeliveryDays": s["avgDeliveryDays"],
            "ordersFulfilled": 30 + _rand.nextInt(200),
          }).toList(),
      "returnRate": 2.3,
      "repeatPurchaseRate": 34.6,
    };
  }

  // ---------------------------------------------------------------------
  // Seed data — "Seventh": premium streetwear, drop-based catalog.
  // ---------------------------------------------------------------------
  void _seed() {
    _categories = [
      {"id": "cat-hoodies", "name": "Hoodies"},
      {"id": "cat-outerwear", "name": "Outerwear"},
      {"id": "cat-tees", "name": "Tees"},
      {"id": "cat-bottoms", "name": "Bottoms"},
      {"id": "cat-accessories", "name": "Accessories"},
    ];

    final catalogSpec = <Map<String, dynamic>>[
      {"name": "V2 Hoodie — Cloud", "cat": "cat-hoodies", "price": 8900.0, "old": 11200.0, "badge": "New", "desc": "Double-lined hood, dropped shoulder seam, brushed interior fleece. 420gsm heavyweight cotton."},
      {"name": "V2 Hoodie — Ink Black", "cat": "cat-hoodies", "price": 8900.0, "old": null, "badge": "Bestseller", "desc": "Our signature boxy silhouette in triple-black. Ribbed cuffs, kangaroo pocket."},
      {"name": "Archive Hoodie — Olive", "cat": "cat-hoodies", "price": 9400.0, "old": 12000.0, "badge": null, "desc": "Garment-dyed for a worn-in look from day one. Oversized fit."},
      {"name": "Half-Zip Fleece — Stone", "cat": "cat-hoodies", "price": 7600.0, "old": null, "badge": null, "desc": "Mid-weight quarter-zip in brushed stone fleece with woven chest patch."},
      {"name": "Coach Jacket — Rust", "cat": "cat-outerwear", "price": 12500.0, "old": 15800.0, "badge": "New", "desc": "Water-resistant nylon shell, snap-button placket, taped seams."},
      {"name": "Trucker Jacket — Washed Denim", "cat": "cat-outerwear", "price": 13900.0, "old": null, "badge": "Bestseller", "desc": "14oz washed denim, corduroy collar, antique brass hardware."},
      {"name": "Puffer Vest — Wood", "cat": "cat-outerwear", "price": 10800.0, "old": null, "badge": null, "desc": "Packable insulation, storm flap zip, two hand-warmer pockets."},
      {"name": "Windbreaker — Paper", "cat": "cat-outerwear", "price": 9900.0, "old": 12400.0, "badge": null, "desc": "Ultralight ripstop shell, packs into its own chest pocket."},
      {"name": "Boxy Tee — Ink Black", "cat": "cat-tees", "price": 3200.0, "old": null, "badge": "Bestseller", "desc": "220gsm heavyweight cotton, dropped shoulder, raw hem finish."},
      {"name": "Boxy Tee — Paper White", "cat": "cat-tees", "price": 3200.0, "old": null, "badge": null, "desc": "Same fit as Ink Black in an off-white heavyweight cotton."},
      {"name": "Long Sleeve Tee — Olive", "cat": "cat-tees", "price": 3800.0, "old": 4600.0, "badge": null, "desc": "Ribbed crewneck, extended cuffs, garment-washed for softness."},
      {"name": "Graphic Tee — Vol. 07", "cat": "cat-tees", "price": 3600.0, "old": null, "badge": "New", "desc": "Limited drop print on the back panel. Numbered edition."},
      {"name": "Pocket Tee — Wood", "cat": "cat-tees", "price": 3000.0, "old": null, "badge": null, "desc": "Everyday relaxed tee with a single chest pocket."},
      {"name": "Cargo Pant — Olive", "cat": "cat-bottoms", "price": 7200.0, "old": 8900.0, "badge": "Bestseller", "desc": "Six-pocket utility cargo in a tapered fit, ripstop cotton."},
      {"name": "Cargo Pant — Ink Black", "cat": "cat-bottoms", "price": 7200.0, "old": null, "badge": null, "desc": "Same tapered cargo fit in triple black with matte hardware."},
      {"name": "Sweatpant — Cloud", "cat": "cat-bottoms", "price": 6400.0, "old": null, "badge": null, "desc": "Brushed fleece jogger with elastic cuffs and drawcord waist."},
      {"name": "Denim — Straight Wash", "cat": "cat-bottoms", "price": 8100.0, "old": 9600.0, "badge": null, "desc": "Rigid 13oz selvedge denim, straight leg, mid rise."},
      {"name": "Woven Cap — Ink Black", "cat": "cat-accessories", "price": 2200.0, "old": null, "badge": null, "desc": "Structured 6-panel cap with woven Seventh patch."},
      {"name": "Crossbody Bag — Wood", "cat": "cat-accessories", "price": 5400.0, "old": null, "badge": "New", "desc": "Water-resistant canvas crossbody with leather trim detailing."},
      {"name": "Ribbed Beanie — Olive", "cat": "cat-accessories", "price": 1800.0, "old": null, "badge": null, "desc": "Heavyweight ribbed knit beanie, fleece-lined for warmth."},
      {"name": "Canvas Tote — Paper", "cat": "cat-accessories", "price": 2600.0, "old": 3200.0, "badge": null, "desc": "Heavy 16oz canvas tote, reinforced base and handles."},
    ];

    _products = List.generate(catalogSpec.length, (i) {
      final spec = catalogSpec[i];
      final id = "p${i + 1}";
      final catId = spec["cat"] as String;
      final category = _categories.firstWhere((c) => c["id"] == catId);
      final isApparel = catId != "cat-accessories";
      final sizes = isApparel ? ["S", "M", "L", "XL"] : ["One Size"];
      final variants = List.generate(sizes.length, (vi) {
        // A couple of products get thin/zero stock so low-stock & sold-out states are visible.
        final lowStockProduct = i == 13; // Cargo Pant — Olive
        final soldOutVariant = i == 1 && vi == 3; // V2 Hoodie Ink Black, XL
        final stock = soldOutVariant ? 0 : (lowStockProduct ? 2 + vi : 8 + _rand.nextInt(40));
        return {
          "id": "$id-v${vi + 1}",
          "sku": "SVN-${id.toUpperCase()}-${sizes[vi].replaceAll(" ", "")}",
          "size": sizes[vi],
          "color": null,
          "price": spec["price"],
          "stockQty": stock,
        };
      });
      return {
        "id": id,
        "name": spec["name"],
        "basePrice": spec["price"],
        "oldPrice": spec["old"],
        "images": [
          "https://picsum.photos/seed/sw-$id-a/900/1100",
          "https://picsum.photos/seed/sw-$id-b/900/1100",
          "https://picsum.photos/seed/sw-$id-c/900/1100",
        ],
        "category": category,
        "variants": variants,
        // Rating/reviewCount are derived from `_reviews` below (never a
        // standalone random number) so the two never drift apart — a
        // product with 0 seeded reviews genuinely shows 0, not a fake count.
        "rating": 0.0,
        "reviewCount": 0,
        "badge": spec["badge"],
        "description": spec["desc"],
      };
    });

    _reviews = {
      "p1": [
        {"id": "rev-1", "userName": "Ayesha K.", "rating": 5.0, "comment": "Fabric quality is amazing, true to size. Fast delivery to Lahore!", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {"id": "rev-2", "userName": "Bilal A.", "rating": 4.0, "comment": "Great hoodie, packaging could be sturdier.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
        {"id": "rev-3", "userName": "Noor F.", "rating": 5.0, "comment": "Softest hoodie I own, the Cloud colorway photographs even better in person.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      ],
      "p2": [
        {"id": "rev-4", "userName": "Sana M.", "rating": 5.0, "comment": "Exactly as shown in pictures. Ordering another one.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
        {"id": "rev-5", "userName": "Fahad Q.", "rating": 4.0, "comment": "Triple black is genuinely deep black, no fading after two washes.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 22)).toIso8601String()},
      ],
      "p5": [
        {"id": "rev-6", "userName": "Omar F.", "rating": 5.0, "comment": "The rust colorway is even better in person. Water resistance actually works.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
      ],
      "p6": [
        {"id": "rev-7", "userName": "Hira B.", "rating": 4.0, "comment": "Denim is stiff at first but breaks in nicely after a week.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      ],
      "p9": [
        {"id": "rev-8", "userName": "Hamza R.", "rating": 5.0, "comment": "Best boxy tee I've bought locally. Heavyweight cotton feels premium.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {"id": "rev-9", "userName": "Zara N.", "rating": 4.0, "comment": "Runs slightly large, sized down would've been perfect.", "images": [], "verified": false, "createdAt": DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      ],
      "p12": [
        {"id": "rev-10", "userName": "Ali R.", "rating": 5.0, "comment": "Numbered edition print is crisp, no cracking after wash.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      ],
      "p14": [
        {"id": "rev-11", "userName": "Usman T.", "rating": 5.0, "comment": "These cargos are on constant rotation now. Fit is perfect.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {"id": "rev-12", "userName": "Fatima S.", "rating": 3.0, "comment": "Good pants but the olive shade runs a bit lighter than shown.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      ],
      "p17": [
        {"id": "rev-13", "userName": "Bilal A.", "rating": 4.0, "comment": "Selvedge denim holds up well, true to size in the waist.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      ],
      "p19": [
        {"id": "rev-14", "userName": "Ayesha K.", "rating": 5.0, "comment": "Bag fits a 13-inch laptop plus daily essentials, love the leather trim.", "images": [], "verified": true, "createdAt": DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      ],
    };
    _reviewSeq = 15;
    for (final entry in _reviews.entries) {
      final p = _products.firstWhere((p) => p["id"] == entry.key, orElse: () => {});
      if (p.isEmpty) continue;
      p["reviewCount"] = entry.value.length;
      p["rating"] = entry.value.fold(0.0, (s, r) => s + (r["rating"] as num)) / entry.value.length;
    }

    _addresses = [
      {"id": "addr-1", "label": "Home", "line1": "House 12, Street 4, DHA Phase 5", "city": "Lahore", "phone": "+923001234567", "isDefault": true},
      {"id": "addr-2", "label": "Office", "line1": "Suite 302, Tricon Corporate, Gulberg III", "city": "Lahore", "phone": "+923214567890", "isDefault": false},
    ];

    _coupons = [
      {"code": "WELCOME10", "description": "10% off your first order", "discountLabel": "10% OFF", "discountType": "percentage", "discountValue": 10, "validUntil": DateTime.now().add(const Duration(days: 30)).toIso8601String(), "usageCount": 214, "usageLimit": 1000, "active": true},
      {"code": "FLASH500", "description": "Flat Rs 500 off orders above Rs 3000", "discountLabel": "Rs 500 OFF", "discountType": "fixed", "discountValue": 500, "validUntil": DateTime.now().add(const Duration(days: 5)).toIso8601String(), "usageCount": 88, "usageLimit": 500, "active": true},
      {"code": "FREESHIP", "description": "Free shipping on all orders", "discountLabel": "FREE SHIPPING", "discountType": "fixed", "discountValue": 200, "validUntil": DateTime.now().add(const Duration(days: 15)).toIso8601String(), "usageCount": 431, "usageLimit": 2000, "active": true},
      {"code": "VOL07", "description": "15% off the Volume 07 drop", "discountLabel": "15% OFF", "discountType": "percentage", "discountValue": 15, "validUntil": DateTime.now().add(const Duration(days: 3)).toIso8601String(), "usageCount": 56, "usageLimit": 300, "active": true},
    ];

    _notifications = [
      {"id": "n1", "title": "Order Shipped", "body": "Your order SVN-1002 is on its way!", "type": "order", "read": false, "createdAt": DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
      {"id": "n2", "title": "Flash Sale Live", "body": "Up to 50% off — today only.", "type": "promo", "read": true, "createdAt": DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      {"id": "n3", "title": "Welcome to Seventh", "body": "Thanks for joining — enjoy 10% off with WELCOME10.", "type": "general", "read": true, "createdAt": DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {"id": "n4", "title": "Price Drop", "body": "Coach Jacket — Rust just dropped to Rs 12,500.", "type": "promo", "read": false, "createdAt": DateTime.now().subtract(const Duration(hours: 20)).toIso8601String()},
      {"id": "n5", "title": "Review Reminder", "body": "How's your V2 Hoodie — Cloud? Leave a review and earn loyalty points.", "type": "general", "read": true, "createdAt": DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
    ];
    _notifSeq = 6;

    _orders = List.generate(5, (i) {
      final statuses = ["delivered", "delivered", "shipped", "confirmed", "delivered"];
      final daysAgo = [28, 21, 9, 3, 45];
      final items = _products.skip(i * 2).take(2).map((p) => {
            "id": "line-hist-$i-${p["id"]}",
            "productId": p["id"],
            "variantId": (p["variants"] as List).first["id"],
            "name": p["name"],
            "imageUrl": (p["images"] as List).first,
            "price": p["basePrice"],
            "size": (p["variants"] as List).first["size"],
            "color": null,
            "qty": 1 + (i % 2),
          }).toList();
      final subtotal = items.fold(0.0, (s, it) => s + (it["price"] as num) * (it["qty"] as num));
      final shipping = subtotal >= 5000 ? 0.0 : 200.0;
      final createdAt = DateTime.now().subtract(Duration(days: daysAgo[i]));
      return {
        "id": "ord-${1001 + i}",
        "orderNumber": "SVN-${1001 + i}",
        "status": statuses[i],
        "createdAt": createdAt.toIso8601String(),
        "items": items,
        "subtotal": subtotal,
        "shipping": shipping,
        "discount": 0.0,
        "total": subtotal + shipping,
        "paymentMethod": i.isEven ? "Cash on Delivery" : "JazzCash",
        "paymentStatus": statuses[i] == "delivered" ? "paid" : "pending",
        "address": _addresses.first,
        "timeline": [
          {"stage": "Placed", "at": createdAt.toIso8601String()},
          if (statuses[i] != "placed") {"stage": "Confirmed", "at": createdAt.add(const Duration(hours: 4)).toIso8601String()},
          if (statuses[i] == "shipped" || statuses[i] == "delivered") {"stage": "Shipped", "at": createdAt.add(const Duration(days: 1)).toIso8601String()},
          if (statuses[i] == "delivered") {"stage": "Out for Delivery", "at": createdAt.add(const Duration(days: 2)).toIso8601String()},
          if (statuses[i] == "delivered") {"stage": "Delivered", "at": createdAt.add(const Duration(days: 3)).toIso8601String()},
        ],
      };
    });

    _customers = [
      {"id": "c1", "name": "Ayesha Khan", "email": "ayesha.khan@example.com", "avatar": "https://i.pravatar.cc/150?u=c1", "city": "Lahore", "joinedAt": "2025-11-02", "orderCount": 14, "totalSpent": 128400.0, "status": "active"},
      {"id": "c2", "name": "Bilal Ahmed", "email": "bilal.ahmed@example.com", "avatar": "https://i.pravatar.cc/150?u=c2", "city": "Karachi", "joinedAt": "2025-09-18", "orderCount": 9, "totalSpent": 76200.0, "status": "active"},
      {"id": "c3", "name": "Sana Malik", "email": "sana.malik@example.com", "avatar": "https://i.pravatar.cc/150?u=c3", "city": "Islamabad", "joinedAt": "2026-01-05", "orderCount": 3, "totalSpent": 19800.0, "status": "active"},
      {"id": "c4", "name": "Hamza Raza", "email": "hamza.raza@example.com", "avatar": "https://i.pravatar.cc/150?u=c4", "city": "Faisalabad", "joinedAt": "2025-06-27", "orderCount": 21, "totalSpent": 214600.0, "status": "active"},
      {"id": "c5", "name": "Zara Nawaz", "email": "zara.nawaz@example.com", "avatar": "https://i.pravatar.cc/150?u=c5", "city": "Lahore", "joinedAt": "2025-12-11", "orderCount": 1, "totalSpent": 8900.0, "status": "blocked"},
      {"id": "c6", "name": "Usman Tariq", "email": "usman.tariq@example.com", "avatar": "https://i.pravatar.cc/150?u=c6", "city": "Rawalpindi", "joinedAt": "2025-08-14", "orderCount": 7, "totalSpent": 54300.0, "status": "active"},
      {"id": "c7", "name": "Fatima Sheikh", "email": "fatima.sheikh@example.com", "avatar": "https://i.pravatar.cc/150?u=c7", "city": "Multan", "joinedAt": "2025-10-30", "orderCount": 5, "totalSpent": 41200.0, "status": "active"},
      {"id": "c8", "name": "Omar Farooq", "email": "omar.farooq@example.com", "avatar": "https://i.pravatar.cc/150?u=c8", "city": "Karachi", "joinedAt": "2026-02-19", "orderCount": 2, "totalSpent": 15600.0, "status": "active"},
    ];

    _staff = [
      {"id": "s1", "name": "Usman (Owner)", "email": "owner@seventh.pk", "role": "owner", "status": "active"},
      {"id": "s2", "name": "Hira Baig", "email": "hira@seventh.pk", "role": "manager", "status": "active"},
      {"id": "s3", "name": "Ali Raza", "email": "ali@seventh.pk", "role": "catalog_editor", "status": "active"},
      {"id": "s4", "name": "Noor Fatima", "email": "noor@seventh.pk", "role": "support", "status": "active"},
    ];

    _suppliers = [
      {"id": "sup1", "name": "Lahore Textile Co.", "feedType": "API", "productsSupplied": 86, "fulfillmentRate": 96.2, "avgDeliveryDays": 3.1, "status": "active", "lastSync": DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
      {"id": "sup2", "name": "Karachi Apparel Hub", "feedType": "CSV", "productsSupplied": 54, "fulfillmentRate": 91.4, "avgDeliveryDays": 4.6, "status": "active", "lastSync": DateTime.now().subtract(const Duration(hours: 20)).toIso8601String()},
      {"id": "sup3", "name": "Faisalabad Knitwear", "feedType": "Manual", "productsSupplied": 22, "fulfillmentRate": 88.0, "avgDeliveryDays": 5.8, "status": "paused", "lastSync": DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
    ];

    _inventory = _products.expand((p) {
      return (p["variants"] as List).map((v) => {
            "sku": v["sku"],
            "productId": p["id"],
            "productName": "${p["name"]} (${v["size"]})",
            "warehouseLocation": "WH-${1 + _rand.nextInt(3)}",
            "stockQty": v["stockQty"],
            "lowStockThreshold": 5,
            "lastRestockedAt": DateTime.now().subtract(Duration(days: _rand.nextInt(20))).toIso8601String(),
          });
    }).toList();
  }
}
