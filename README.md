# Seventh — Flutter E-Commerce Platform

A single-codebase Flutter e-commerce platform (Customer App + Admin Web Panel) backed by a NestJS + PostgreSQL API. Built as **Seventh**, a premium streetwear storefront, and designed from day one to launch as a **dropshipping** store and evolve into **own-inventory** selling without a rewrite (see [`docs/PRD.md`](./docs/PRD.md)).

**This is a portfolio/demo build.** The Flutter app ships with a full in-memory mock backend baked in, so it runs standalone — no database, no server, and no third-party credentials required to try every flow end to end. See [§5 Demo Mode](#5-demo-mode) below.

Related docs: [`PRD.md`](./docs/PRD.md) · [`DESIGN_FLOW.md`](./docs/DESIGN_FLOW.md) · [`ARCHITECTURE.md`](./docs/ARCHITECTURE.md)

---

## 1. What's Here

**Customer app** — splash, phone/OTP + social login, home (hero, spotlight, featured grid), search with filters/sort, product detail (gallery, variants, live reviews), cart, a 4-step checkout (address → delivery → payment → review), order success + tracking + order history, wishlist, notifications, coupons/offers, profile.

**Admin web panel** — dashboard (revenue/orders/customers trend charts, order status breakdown, top products, low-stock alerts, recent activity), product management (CRUD + CSV bulk import), inventory, orders, customers, promotions, suppliers, staff, and reports — all behind a responsive sidebar/bottom-nav shell with role-based menu visibility (Owner/Manager/Support/Catalog Editor).

**Backend** — NestJS + TypeORM API covering auth (OTP + social), products/variants/categories, cart, orders, suppliers, and payment adapters (JazzCash/Easypaisa/Card — sandbox-shaped, demo mode). Product/cart/order data is real (PostgreSQL via TypeORM); notifications/reviews/promotions/inventory/customers/staff are served from an in-memory seeded store (see [§8](#8-backend-notes)) so the API is fully exercisable without extra schema work for this demo.

---

## 2. Tech Stack

- **Frontend:** Flutter (Material 3), Riverpod, GoRouter, Clean Architecture (feature-first), fl_chart, Google Fonts
- **Backend:** NestJS, TypeORM, PostgreSQL, class-validator
- **Payments (demo-mode adapters):** Cash on Delivery, JazzCash, Easypaisa, Card
- **Notifications:** Firebase Cloud Messaging (wiring present; push requires a real Firebase project — see limitations)

---

## 3. Project Structure

```
ecommerce-platform/
 ├─ app/                              # Flutter app (customer + admin targets)
 │   ├─ lib/
 │   │   ├─ core/
 │   │   │   ├─ config/               # AppConfig — demo mode / API base URL switch
 │   │   │   ├─ network/              # Dio client + in-app mock backend
 │   │   │   ├─ routing/              # GoRouter config (customer + admin)
 │   │   │   ├─ theme/                # Design tokens (colors, type, spacing, motion)
 │   │   │   └─ widgets/              # Shared empty/error/shimmer/product-card widgets
 │   │   ├─ features/                 # Feature-first: data/domain/presentation per feature
 │   │   │   ├─ auth/ catalog/ product_detail/ cart/ checkout/ orders/
 │   │   │   ├─ wishlist/ notifications/ reviews/ promotions/ profile/ splash/
 │   │   │   └─ admin/                # dashboard, products, inventory, orders_admin,
 │   │   │                            # promotions_admin, customers, suppliers, staff, reports
 │   │   ├─ main_customer.dart
 │   │   └─ main_admin.dart
 │   └─ pubspec.yaml
 │
 ├─ backend/                          # NestJS API
 │   ├─ src/
 │   │   ├─ auth/ products/ cart/ orders/ suppliers/ payments/
 │   │   ├─ users/ admin/ notifications/ promotions/ reviews/ inventory/
 │   │   ├─ common/mock-data/         # Seeded demo data for the in-memory modules
 │   │   └─ entities/                 # TypeORM entities (User, Product, Order, Cart, ...)
 │   └─ package.json
 │
 ├─ docs/                             # PRD, design flow, architecture
 └─ README.md
```

---

## 4. Design System

Centralized in `app/lib/core/theme/app_theme.dart`:

- **Palette:** warm paper background, ink-black type, wood/olive/rust accents — an editorial streetwear look, not default Material.
- **Type:** Anton (condensed display) for headlines, Archivo for body/UI, via Google Fonts.
- **Tokens:** `AppColors`, `AppRadii`, `AppSpacing`, `AppDurations` — every screen pulls from these instead of ad-hoc values.
- **Motion:** shared page-transition timings, shimmer loaders, hero image transitions between product cards and product detail, animated counters on the admin dashboard, optimistic cart/wishlist updates.

The same tokens theme both the customer app and the admin panel so the two feel like one product.

---

## 5. Demo Mode

`app/lib/core/config/app_config.dart` exposes `AppConfig.demoMode` (**default `true`**). When on, every repository's Dio call is intercepted by `app/lib/core/network/mock_backend.dart` — an in-memory fake REST API with realistic seed data (20+ products with variants/stock, order history, reviews, coupons, notifications, customers, suppliers, inventory, admin dashboard stats) and simulated network latency. Nothing hits the network; the app is fully interactive offline.

The point of this: the UI code (repositories → Riverpod providers → screens) is written exactly as it would be against a real server — swapping modes changes only the transport underneath, not a single widget.

To point the app at a real NestJS deployment instead:

```bash
flutter run \
  --dart-define=DEMO_MODE=false \
  --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
```

**Demo login:** enter any phone number → OTP is always `1234` (shown on-screen as a hint). Google/Apple buttons log in with a deterministic demo profile — no real OAuth call is made.

---

## 6. Getting Started

### Flutter App (Customer) — works standalone, no backend needed
```bash
cd app
flutter pub get
flutter run -t lib/main_customer.dart
```

### Flutter Admin Panel (Web) — works standalone, no backend needed
```bash
cd app
flutter run -t lib/main_admin.dart -d chrome
```

### Backend (optional — only needed if you flip `DEMO_MODE=false`)
```bash
cd backend
npm install
cp .env.example .env      # set DB, Redis, payment gateway keys
npm run migration:run
npm run seed               # populate demo products, customers, and sample orders
npm run start:dev
```

---

## 7. Environment Variables (backend `.env`)

```
DATABASE_URL=postgres://user:pass@localhost:5432/ecommerce
REDIS_URL=redis://localhost:6379
JWT_SECRET=
DEMO_MODE=true             # documents that OTP/social-auth/card payments run in demo mode
JAZZCASH_MERCHANT_ID=      # unused while DEMO_MODE=true
EASYPAISA_STORE_ID=        # unused while DEMO_MODE=true
FCM_SERVER_KEY=            # unused until a real Firebase project is wired
S3_BUCKET=
S3_ACCESS_KEY=
S3_SECRET_KEY=
```

---

## 8. Backend Notes

- **Real, TypeORM-backed:** `products`/`product_variants`/`categories`, `cart`/`cart_items`, `orders`/`order_items`, `users`, `addresses`, `suppliers`/`supplier_products`, `payments`.
- **In-memory, seeded store (no schema migration needed for this demo):** `notifications`, `reviews`, `promotions`, `inventory`, admin `customers`/`staff`, and the `GET /admin/dashboard` aggregate. Each has a real service/repository-style class (`common/mock-data/`) rather than data inlined in controllers — swapping in a TypeORM entity later is a contained change, not a rewrite.
- **Payments:** JazzCash/Easypaisa/Card adapters are sandbox-shaped and documented as demo mode — they simulate a gateway round-trip and return a realistic success/decline rather than calling a real merchant account. COD is the fully "real" path (no external call needed).
- **Auth:** OTP is generated and returned directly in the API response (`devCode`) instead of sent via SMS — clearly logged as demo behavior. Social login accepts any token and returns a deterministic profile rather than verifying against Google/Apple.

---

## 9. Known Limitations / What a Production Launch Would Still Need

- Real SMS gateway for OTP delivery (Twilio/Telenor/Zong) in place of the `devCode` response.
- Real Google/Apple ID token verification in `social-auth.service.ts`.
- Real payment gateway credentials + signed callback handling for JazzCash/Easypaisa/Stripe-PayFast.
- A generated `InitSchema` TypeORM migration once a live Postgres instance is reachable (`synchronize: true` is dev-only, see `app.module.ts`).
- Moving `notifications`/`reviews`/`promotions`/`inventory`/`customers`/`staff` from the in-memory store to TypeORM entities once persistence across backend restarts is required.
- Wishlist and delivery-address endpoints currently only exist in the Flutter mock backend (no backend-side entity yet) — fine for the demo, would need a `wishlist`/`addresses` module for a real deployment.
- Push notifications need a real Firebase project (`google-services.json` / `GoogleService-Info.plist`) wired in; the FCM client code is present but untested against a live project.
- No automated backend test suite yet (`*.spec.ts`); `app/test/widget_test.dart` is a starter — expand both as the app stabilizes.

---

## 10. Testing

```bash
cd app
flutter test

cd backend
npm run build   # type-checks the whole API
```

---

## 11. Screenshots

_Add screenshots/GIFs of Home, Product Detail, Checkout, and the Admin Dashboard here before sharing this repo publicly._

---

## 12. App Icons & Splash

Launcher icon generation is pre-configured in `pubspec.yaml` via `flutter_launcher_icons`:
```bash
cd app
# Drop a 1024x1024 PNG at assets/icons/app_icon.png first
dart run flutter_launcher_icons
```

---

## 13. Deployment Notes (for a real launch)

- **Backend:** containerize with a standard NestJS Dockerfile, deploy behind a load balancer; point `DATABASE_URL`/`REDIS_URL` at managed Postgres/Redis. Set `DEMO_MODE=false` and configure real provider credentials first.
- **Flutter Web:** `flutter build web --target=lib/main_customer.dart` and `--target=lib/main_admin.dart` with `--dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=...`, served from separate paths/subdomains.
- **Mobile:** standard `flutter build apk` / `flutter build ipa`.

---

## 14. Contribution Notes

- Feature-first Clean Architecture: each feature folder has `data/`, `domain/`, `presentation/`.
- New products default to `fulfillment_type: DROPSHIP` unless explicitly marked `OWN_STOCK`.
- UI follows the tokens in `core/theme/` — no default Material styling without theming.
- Repositories always go through `ApiClient.instance.dio`; never call `http`/`dio` directly from a widget.
