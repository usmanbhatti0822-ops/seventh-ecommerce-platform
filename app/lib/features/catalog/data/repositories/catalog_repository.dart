import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";
import "../../domain/entities/product.dart";

class CatalogRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<Product>>> fetchProducts({String? categoryId, String? search}) async {
    try {
      final res = await _dio.get("/products", queryParameters: {
        if (categoryId != null) "categoryId": categoryId,
        if (search != null && search.isNotEmpty) "search": search,
      });
      final products = (res.data as List).map((j) => Product.fromJson(j)).toList();
      return ApiSuccess(products);
    } on DioException catch (e) {
      // Falls back to mock data so the UI stays usable while the backend
      // isn't reachable yet (local dev / offline demo). Remove this fallback
      // once the backend is deployed and reachable from the app builds.
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return ApiSuccess(mockProducts);
      }
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not load products");
    }
  }

  Future<ApiResult<Product>> fetchProduct(String id) async {
    try {
      final res = await _dio.get("/products/$id");
      return ApiSuccess(Product.fromJson(res.data));
    } on DioException catch (e) {
      final fallback = mockProducts.where((p) => p.id == id);
      if (fallback.isNotEmpty) return ApiSuccess(fallback.first);
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not load product");
    }
  }
}
