import "package:go_router/go_router.dart";
import "../../features/admin/dashboard/presentation/screens/dashboard_screen.dart";
import "../../features/admin/products/presentation/screens/products_screen.dart";
import "../../features/admin/suppliers/presentation/screens/suppliers_screen.dart";
import "../../features/admin/orders_admin/presentation/screens/orders_admin_screen.dart";
import "../../features/admin/promotions_admin/presentation/screens/promotions_admin_screen.dart";
import "../../features/admin/customers/presentation/screens/customers_admin_screen.dart";
import "../../features/admin/reports/presentation/screens/reports_admin_screen.dart";
import "../../features/admin/staff/presentation/screens/staff_screen.dart";
import "../../features/admin/inventory/presentation/screens/inventory_screen.dart";

final GoRouter adminRouter = GoRouter(
  initialLocation: "/admin",
  routes: [
    GoRoute(path: "/admin", builder: (context, state) => const DashboardScreen()),
    GoRoute(path: "/admin/products", builder: (context, state) => const AdminProductsScreen()),
    GoRoute(path: "/admin/inventory", builder: (context, state) => const AdminInventoryScreen()),
    GoRoute(path: "/admin/suppliers", builder: (context, state) => const AdminSuppliersScreen()),
    GoRoute(path: "/admin/orders", builder: (context, state) => const AdminOrdersScreen()),
    GoRoute(path: "/admin/promotions", builder: (context, state) => const AdminPromotionsScreen()),
    GoRoute(path: "/admin/customers", builder: (context, state) => const AdminCustomersScreen()),
    GoRoute(path: "/admin/staff", builder: (context, state) => const AdminStaffScreen()),
    GoRoute(path: "/admin/reports", builder: (context, state) => const AdminReportsScreen()),
  ],
);
