# Design Flow Document
## Flutter E-Commerce Platform — User Journeys & Screen Flow

---

## 1. Customer Journey (Mobile + Web)

```
Splash → Onboarding (skip if logged in)
   │
   ├─ Login/Signup (Phone OTP / Email / Google / Apple) ──or── Continue as Guest
   │
   ▼
Home
 ├─ Banners / Flash Sale strip
 ├─ Categories grid
 ├─ Recommended / Trending products
 │
 ├──▶ Search ──▶ Search Results ──▶ Product Detail
 ├──▶ Category ──▶ Product Listing (filters/sort) ──▶ Product Detail
 │
 ▼
Product Detail
 ├─ Image gallery, variants (size/color), price, stock
 ├─ Reviews & ratings
 ├─ "Add to Cart" / "Buy Now" (micro-animation feedback)
 ├─ Add to Wishlist
 │
 ▼
Cart
 ├─ Edit quantity / remove / save-for-later
 ├─ Apply coupon
 │
 ▼
Checkout
 ├─ Select/Add Address
 ├─ Select Shipping Method
 ├─ Select Payment (COD / JazzCash / Easypaisa / Card)
 ├─ Order Summary → Place Order
 │   └─ If COD + high value → OTP confirmation step
 ▼
Order Confirmation
 │
 ▼
Order Tracking (status timeline) ──▶ Order History
 │
 ▼
Delivered ──▶ Rate & Review prompt
```

**Secondary flows hanging off Home/Profile:**
- Profile → Addresses, Payment methods, Order history, Wishlist, Notifications, Support/Chat, Settings (language, dark mode)
- Notification tap → deep link directly into relevant Order/Product/Promo screen

---

## 2. Admin Journey (Web Panel)

```
Admin Login (role-based: Owner / Manager / Support / Catalog Editor)
   │
   ▼
Dashboard (sales, orders, top products, alerts)
   │
   ├──▶ Products
   │     ├─ Add/Edit product, variants, media
   │     ├─ Bulk import (CSV)
   │     └─ Supplier mapping (Phase 1): link product → supplier, set cost/sell margin
   │
   ├──▶ Orders
   │     ├─ New Orders queue → Confirm → Assign fulfillment (Supplier / Warehouse)
   │     ├─ Update status (shipped/out for delivery/delivered)
   │     └─ Returns/Refunds queue
   │
   ├──▶ Suppliers (Phase 1 critical)
   │     ├─ Supplier list, contact/feed info
   │     └─ Stock-sync / price-sync log
   │
   ├──▶ Inventory (grows in importance in Phase 2)
   │     └─ Stock levels, low-stock alerts
   │
   ├──▶ Promotions
   │     └─ Coupons, flash sales, banners
   │
   ├──▶ Customers
   │     └─ View profile, order history, block/flag
   │
   └──▶ Reports & Staff/Roles management
```

---

## 3. Order Lifecycle (State Machine)

```
Placed → Confirmed → (Dropship: Sent to Supplier | Own-stock: Packed)
     → Shipped → Out for Delivery → Delivered
     → (optional) Return Requested → Return Approved → Refunded
     └─ Cancelled (allowed only before "Shipped")
```

Each transition triggers: push notification to customer + timeline update + (if applicable) supplier/warehouse notification.

---

## 4. Design System Direction (Modern & Animated)

- **Style:** Material 3, rounded corners, soft elevation/shadows, bold but limited accent color + neutral base
- **Motion:**
  - Hero animations: product thumbnail → detail image
  - Shared-axis transitions between listing → detail
  - Skeleton shimmer loaders (never blank/spinner-only screens)
  - Micro-interactions: cart bounce on add, heart-pop on wishlist, button ripple + scale
  - Animated bottom nav (icon morph/indicator slide)
  - Staggered list entrance animations on Home/Category grids
- **Responsiveness:** mobile (bottom nav), tablet (rail nav), web/desktop (top nav + sidebar for admin)
- **Dark mode:** full theme parity, not an afterthought

---

## 5. Next Deliverable
→ Architecture Document (system design, DB schema outline, API contracts)
