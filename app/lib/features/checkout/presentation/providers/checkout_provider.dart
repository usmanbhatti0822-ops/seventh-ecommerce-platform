import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/addresses_repository.dart";
import "../../../../core/network/api_result.dart";

final addressesRepositoryProvider = Provider((ref) => AddressesRepository());

final addressesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(addressesRepositoryProvider);
  final result = await repo.list();
  return switch (result) {
    ApiSuccess(data: final addresses) => addresses,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});

enum DeliveryOption { standard, express }

extension DeliveryOptionX on DeliveryOption {
  String get label => this == DeliveryOption.express ? "Express (1-2 days)" : "Standard (3-5 days)";
  double get fee => this == DeliveryOption.express ? 350 : 0;
}

/// Step index within the checkout flow: 0=Address, 1=Delivery, 2=Payment, 3=Review.
final checkoutStepProvider = StateProvider<int>((ref) => 0);
final selectedAddressIdProvider = StateProvider<String?>((ref) => null);
final deliveryOptionProvider = StateProvider<DeliveryOption>((ref) => DeliveryOption.standard);
final paymentMethodProvider = StateProvider<String>((ref) => "Cash on Delivery");
final appliedCouponProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final placingOrderProvider = StateProvider<bool>((ref) => false);
