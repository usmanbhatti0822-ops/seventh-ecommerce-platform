import { UserRole } from "../../entities/user.entity";

/**
 * Shape definitions for the demo-mode in-memory data used by the
 * notifications / reviews / promotions / inventory / users / admin modules.
 * There is deliberately no TypeORM entity behind these — see the module-level
 * doc comments on each store for why (out of scope for this portfolio demo).
 */

export type NotificationType = "order_update" | "promotion" | "system" | "review_reminder";

export interface MockNotification {
  id: string;
  /** Target customer id, or `null` for a broadcast notification (e.g. a flash-sale banner) shown to every user. */
  userId: string | null;
  type: NotificationType;
  title: string;
  message: string;
  read: boolean;
  createdAt: string; // ISO 8601
}

export interface MockReview {
  id: string;
  productId: string;
  productName: string;
  rating: number; // 1-5
  comment: string;
  reviewerName: string;
  verifiedPurchase: boolean;
  createdAt: string;
}

export type DiscountType = "percentage" | "fixed" | "free_shipping";

export interface MockPromotion {
  id: string;
  code: string;
  description: string;
  discountType: DiscountType;
  /** Percentage points, PKR amount, or 0 for free_shipping — interpretation depends on discountType. */
  discountValue: number;
  validFrom: string;
  validUntil: string;
  usageCount: number;
  /** 0 means unlimited. */
  usageLimit: number;
  active: boolean;
}

export interface StockMovement {
  id: string;
  type: "in" | "out";
  quantity: number;
  reason: string;
  occurredAt: string;
}

export interface MockInventoryRecord {
  id: string;
  sku: string;
  productName: string;
  variantLabel?: string;
  warehouseLocation: string;
  stockQty: number;
  lowStockThreshold: number;
  lastRestockedAt: string;
  movements: StockMovement[];
}

export interface MockCustomer {
  id: string;
  name: string;
  email: string;
  phone: string;
  city: string;
  avatarUrl: string;
  joinedAt: string;
  orderCount: number;
  totalSpentPkr: number;
  status: "active" | "blocked";
}

export type StaffRole = Exclude<UserRole, UserRole.CUSTOMER>;

export interface MockStaffMember {
  id: string;
  name: string;
  email: string;
  role: StaffRole;
  joinedAt: string;
  active: boolean;
}

export interface TopProductSummary {
  productId: string;
  productName: string;
  unitsSold: number;
  revenuePkr: number;
}

export interface RecentOrderSummary {
  orderRef: string;
  customerName: string;
  city: string;
  itemSummary: string;
  totalPkr: number;
  status: "PLACED" | "CONFIRMED" | "SHIPPED" | "DELIVERED" | "CANCELLED";
  placedAt: string;
}

export interface DashboardSummary {
  revenue: { last30DaysPkr: number; last7DaysPkr: number; changePct: number };
  orders: { last30Days: number; last7Days: number; changePct: number };
  customers: { total: number; newLast30Days: number };
  topProducts: TopProductSummary[];
  recentOrders: RecentOrderSummary[];
}
