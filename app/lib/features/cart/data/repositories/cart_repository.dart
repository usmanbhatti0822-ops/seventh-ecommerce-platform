import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

class CartRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<Map<String, dynamic>>> getCart() async {
    try {
      final res = await _dio.get("/cart");
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> addItem(String variantId, int qty) async {
    try {
      final res = await _dio.post("/cart/items", data: {"variantId": variantId, "qty": qty});
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<void>> updateItemQty(String itemId, int qty) async {
    try {
      await _dio.patch("/cart/items/$itemId", data: {"qty": qty});
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<void>> removeItem(String itemId) async {
    try {
      await _dio.delete("/cart/items/$itemId");
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  String _msg(DioException e) => e.response?.data?["message"]?.toString() ?? "Cart action failed";
}
