import "package:dio/dio.dart";
import "../../../../../core/network/api_client.dart";
import "../../../../../core/network/api_result.dart";

class AdminProductsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<Map<String, dynamic>>> bulkImport(List<Map<String, dynamic>> rows) async {
    try {
      final res = await _dio.post("/products/import", data: rows);
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Import failed");
    }
  }

  Future<ApiResult<Map<String, dynamic>>> create(Map<String, dynamic> product) async {
    try {
      final res = await _dio.post("/products", data: product);
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not create product");
    }
  }

  Future<ApiResult<Map<String, dynamic>>> update(String id, Map<String, dynamic> changes) async {
    try {
      final res = await _dio.patch("/products/$id", data: changes);
      return ApiSuccess(res.data);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not update product");
    }
  }

  Future<ApiResult<void>> delete(String id) async {
    try {
      await _dio.delete("/products/$id");
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not delete product");
    }
  }
}

/// Parses a simple CSV (header row + data rows) into product import payloads.
/// Expected columns: name,basePrice,description,categoryId
List<Map<String, dynamic>> parseProductCsv(String csv) {
  final lines = csv.trim().split("\n").where((l) => l.trim().isNotEmpty).toList();
  if (lines.length < 2) return [];
  final headers = lines.first.split(",").map((h) => h.trim()).toList();
  return lines.skip(1).map((line) {
    final values = line.split(",");
    final row = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < values.length; i++) {
      final key = headers[i];
      final value = values[i].trim();
      row[key] = key == "basePrice" ? double.tryParse(value) ?? 0 : value;
    }
    return row;
  }).toList();
}
