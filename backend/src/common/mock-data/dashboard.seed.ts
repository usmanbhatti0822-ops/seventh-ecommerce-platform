import { CUSTOMERS } from "./customers.seed";
import { daysAgo } from "./id.util";
import { TopProductSummary, RecentOrderSummary } from "./types";

/** Static slices of the admin dashboard (`GET /admin/dashboard`) that aren't derived from the customer directory. */
export const TOP_PRODUCTS: TopProductSummary[] = [
  { productId: "prod_v2_hoodie_cloud", productName: "V2 Hoodie — Cloud", unitsSold: 312, revenuePkr: 1091688 },
  { productId: "prod_overdye_tee_charcoal", productName: "Overdye Tee — Charcoal", unitsSold: 486, revenuePkr: 826200 },
  { productId: "prod_cargo_pant_olive", productName: "Cargo Pant — Olive", unitsSold: 201, revenuePkr: 703500 },
  { productId: "prod_coach_jacket_ink", productName: "Coach Jacket — Ink", unitsSold: 94, revenuePkr: 611000 },
  { productId: "prod_ribbed_beanie_black", productName: "Ribbed Beanie — Black", unitsSold: 178, revenuePkr: 232400 },
];

export const RECENT_ORDERS: RecentOrderSummary[] = [
  { orderRef: "SVN-10432", customerName: CUSTOMERS[0].name, city: CUSTOMERS[0].city, itemSummary: "V2 Hoodie — Cloud (M)", totalPkr: 6499, status: "SHIPPED", placedAt: daysAgo(0) },
  { orderRef: "SVN-10428", customerName: CUSTOMERS[9].name, city: CUSTOMERS[9].city, itemSummary: "Overdye Tee — Charcoal x2", totalPkr: 3400, status: "PLACED", placedAt: daysAgo(0) },
  { orderRef: "SVN-10417", customerName: CUSTOMERS[1].name, city: CUSTOMERS[1].city, itemSummary: "Coach Jacket — Ink (M)", totalPkr: 8999, status: "CONFIRMED", placedAt: daysAgo(1) },
  { orderRef: "SVN-10390", customerName: CUSTOMERS[2].name, city: CUSTOMERS[2].city, itemSummary: "Cargo Pant — Olive (32)", totalPkr: 4650, status: "SHIPPED", placedAt: daysAgo(3) },
  { orderRef: "SVN-10355", customerName: CUSTOMERS[4].name, city: CUSTOMERS[4].city, itemSummary: "V2 Hoodie — Cloud (L) + Beanie", totalPkr: 7798, status: "DELIVERED", placedAt: daysAgo(6) },
  { orderRef: "SVN-10288", customerName: CUSTOMERS[3].name, city: CUSTOMERS[3].city, itemSummary: "Overdye Tee — Charcoal", totalPkr: 1700, status: "CANCELLED", placedAt: daysAgo(9) },
  { orderRef: "SVN-10201", customerName: CUSTOMERS[9].name, city: CUSTOMERS[9].city, itemSummary: "Coach Jacket — Ink (M)", totalPkr: 8999, status: "DELIVERED", placedAt: daysAgo(14) },
  { orderRef: "SVN-10156", customerName: CUSTOMERS[10].name, city: CUSTOMERS[10].city, itemSummary: "Ribbed Beanie — Black x2", totalPkr: 2600, status: "DELIVERED", placedAt: daysAgo(25) },
];
