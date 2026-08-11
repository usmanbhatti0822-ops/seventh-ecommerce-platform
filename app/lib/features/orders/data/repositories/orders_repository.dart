import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

class OrdersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<dynamic>>> myOrders() async {
    try {
      final res = await _dio.get("/orders");
      return ApiSuccess(res.data as List<dynamic>);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getOrder(String id) async {
    try {
      final res = await _dio.get("/orders/$id");
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? couponCode,
  }) async {
    try {
      final res = await _dio.post("/orders", data: {
        "addressId": addressId,
        "paymentMethod": paymentMethod,
        if (couponCode != null && couponCode.isNotEmpty) "couponCode": couponCode,
      });
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<void>> cancelOrder(String id) async {
    try {
      await _dio.patch("/orders/$id/cancel");
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  /// Admin-only status transition (Placed → Confirmed → Shipped → Out for
  /// Delivery → Delivered), mirrors the backend's `PATCH /orders/:id/status`.
  Future<ApiResult<Map<String, dynamic>>> updateStatus(String id, String status) async {
    try {
      final res = await _dio.patch("/orders/$id/status", data: {"status": status});
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  String _msg(DioException e) => e.response?.data?["message"]?.toString() ?? "Order action failed";
}
