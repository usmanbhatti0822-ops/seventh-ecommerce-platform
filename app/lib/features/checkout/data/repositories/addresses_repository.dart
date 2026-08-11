import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

class AddressesRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<Map<String, dynamic>>>> list() async {
    try {
      final res = await _dio.get("/addresses");
      return ApiSuccess(List<Map<String, dynamic>>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> add(Map<String, dynamic> address) async {
    try {
      final res = await _dio.post("/addresses", data: address);
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  String _msg(DioException e) => e.response?.data?["message"]?.toString() ?? "Could not load addresses";
}
