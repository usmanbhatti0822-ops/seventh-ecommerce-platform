import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

class ReviewsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<Map<String, dynamic>>>> forProduct(String productId) async {
    try {
      final res = await _dio.get("/reviews", queryParameters: {"productId": productId});
      return ApiSuccess(List<Map<String, dynamic>>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not load reviews");
    }
  }

  Future<ApiResult<Map<String, dynamic>>> create({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    try {
      final res = await _dio.post("/reviews", data: {"productId": productId, "rating": rating, "comment": comment});
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not submit review");
    }
  }
}
