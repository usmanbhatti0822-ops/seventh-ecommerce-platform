import "package:go_router/go_router.dart";
import "../../features/splash/presentation/screens/splash_screen.dart";
import "../../features/catalog/presentation/screens/home_screen.dart";
import "../../features/catalog/presentation/screens/search_screen.dart";
import "../../features/auth/presentation/screens/login_screen.dart";
import "../../features/product_detail/presentation/screens/product_detail_screen.dart";
import "../../features/cart/presentation/screens/cart_screen.dart";
import "../../features/checkout/presentation/screens/checkout_screen.dart";
import "../../features/checkout/presentation/screens/order_success_screen.dart";
import "../../features/orders/presentation/screens/order_tracking_screen.dart";
import "../../features/orders/presentation/screens/orders_list_screen.dart";
import "../../features/wishlist/presentation/screens/wishlist_screen.dart";
import "../../features/profile/presentation/screens/profile_screen.dart";
import "../../features/promotions/presentation/screens/coupons_screen.dart";
import "../../features/notifications/presentation/screens/notifications_screen.dart";

final GoRouter customerRouter = GoRouter(
  initialLocation: "/splash",
  routes: [
    GoRoute(path: "/splash", builder: (context, state) => const SplashScreen()),
    GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
    GoRoute(path: "/", builder: (context, state) => const HomeScreen()),
    GoRoute(path: "/search", builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: "/product/:id",
      builder: (context, state) => ProductDetailScreen(productId: state.pathParameters["id"]!),
    ),
    GoRoute(path: "/cart", builder: (context, state) => const CartScreen()),
    GoRoute(path: "/checkout", builder: (context, state) => const CheckoutScreen()),
    GoRoute(
      path: "/order-success",
      builder: (context, state) => OrderSuccessScreen(order: state.extra as Map<String, dynamic>),
    ),
    GoRoute(path: "/orders", builder: (context, state) => const OrdersListScreen()),
    GoRoute(
      path: "/order/:id",
      builder: (context, state) => OrderTrackingScreen(orderId: state.pathParameters["id"]!),
    ),
    GoRoute(path: "/wishlist", builder: (context, state) => const WishlistScreen()),
    GoRoute(path: "/profile", builder: (context, state) => const ProfileScreen()),
    GoRoute(path: "/coupons", builder: (context, state) => const CouponsScreen()),
    GoRoute(path: "/notifications", builder: (context, state) => const NotificationsScreen()),
  ],
);
