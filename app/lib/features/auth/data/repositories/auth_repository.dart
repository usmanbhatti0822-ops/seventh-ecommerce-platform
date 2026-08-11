import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";
import "../../../../core/storage/token_storage.dart";

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<String>> requestOtp(String phone) async {
    try {
      final res = await _dio.post("/auth/otp/request", data: {"phone": phone});
      // devCode is only present in non-production backend responses (see AuthService.requestOtp)
      return ApiSuccess(res.data["devCode"]?.toString() ?? "");
    } on DioException catch (e) {
      return ApiFailure(_message(e));
    }
  }

  Future<ApiResult<void>> verifyOtp(String phone, String code) async {
    try {
      final res = await _dio.post("/auth/otp/verify", data: {"phone": phone, "code": code});
      await TokenStorage.save(res.data["accessToken"]);
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_message(e));
    }
  }

  Future<ApiResult<void>> socialLogin(String provider, String idToken) async {
    try {
      final res = await _dio.post("/auth/social", data: {"provider": provider, "idToken": idToken});
      await TokenStorage.save(res.data["accessToken"]);
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(_message(e));
    }
  }

  Future<void> logout() => TokenStorage.clear();

  String _message(DioException e) =>
      e.response?.data?["message"]?.toString() ?? "Something went wrong. Please try again.";
}
