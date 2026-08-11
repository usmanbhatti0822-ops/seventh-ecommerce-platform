import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

/// Read-side repository for every Admin Panel screen (Dashboard, Customers,
/// Reports, Suppliers, Staff, Inventory). Products/Orders/Promotions reuse
/// their existing customer-side repositories since the underlying resource
/// is the same — this repository only covers the admin-only aggregate views.
class AdminRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<Map<String, dynamic>>> dashboard() => _getMap("/admin/dashboard");
  Future<ApiResult<List<Map<String, dynamic>>>> customers() => _getList("/admin/customers");
  Future<ApiResult<Map<String, dynamic>>> reports() => _getMap("/admin/reports");
  Future<ApiResult<List<Map<String, dynamic>>>> suppliers() => _getList("/admin/suppliers");
  Future<ApiResult<List<Map<String, dynamic>>>> staff() => _getList("/admin/staff");
  Future<ApiResult<List<Map<String, dynamic>>>> inventory() => _getList("/admin/inventory");
  Future<ApiResult<List<Map<String, dynamic>>>> orders() => _getList("/admin/orders");

  Future<ApiResult<Map<String, dynamic>>> _getMap(String path) async {
    try {
      final res = await _dio.get(path);
      return ApiSuccess(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> _getList(String path) async {
    try {
      final res = await _dio.get(path);
      return ApiSuccess(List<Map<String, dynamic>>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(_msg(e));
    }
  }

  String _msg(DioException e) => e.response?.data?["message"]?.toString() ?? "Could not load admin data";
}
