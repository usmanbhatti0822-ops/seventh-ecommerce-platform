import "package:flutter_riverpod/flutter_riverpod.dart";

/// Roles mirror backend UserRole (see backend/src/entities/user.entity.ts).
enum AdminRole { owner, manager, support, catalogEditor }

/// Demo mode: the panel signs in as the Owner role by default so every
/// section is reachable without a separate admin login screen. A real
/// deployment would decode this from the JWT payload issued at admin login.
final adminRoleProvider = StateProvider<AdminRole>((ref) => AdminRole.owner);

/// Which sidebar sections each role is allowed to see — mirrors the @Roles()
/// guards already enforced on the backend (auth/roles.guard.ts), so the UI
/// does not offer actions the API would reject anyway.
const Map<AdminRole, List<String>> roleMenuAccess = {
  AdminRole.owner: ["Dashboard", "Products", "Inventory", "Suppliers", "Orders", "Promotions", "Customers", "Staff", "Reports"],
  AdminRole.manager: ["Dashboard", "Products", "Inventory", "Suppliers", "Orders", "Promotions", "Customers", "Reports"],
  AdminRole.support: ["Dashboard", "Orders", "Customers"],
  AdminRole.catalogEditor: ["Dashboard", "Products", "Inventory"],
};
