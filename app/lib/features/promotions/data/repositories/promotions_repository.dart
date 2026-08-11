import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

class PromotionsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<Map<String, dynamic>>>> list() async {
    try {
      final res = await _dio.get("/promotions");
      return ApiSuccess(List<Map<String, dynamic>>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not load offers");
    }
  }
}
