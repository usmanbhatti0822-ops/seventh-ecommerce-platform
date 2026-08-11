import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";
import "../../../catalog/domain/entities/product.dart";

class WishlistRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<Product>>> list() async {
    try {
      final res = await _dio.get("/wishlist");
      return ApiSuccess((res.data as List).map((j) => Product.fromJson(j)).toList());
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<void>> add(String productId) async {
    try {
      await _dio.post("/wishlist/$productId");
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<void>> remove(String productId) async {
    try {
      await _dio.delete("/wishlist/$productId");
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  String _msg(DioException e) => e.response?.data?["message"]?.toString() ?? "Wishlist action failed";
}
