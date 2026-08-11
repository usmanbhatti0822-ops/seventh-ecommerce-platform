# Architecture Document
## Flutter E-Commerce Platform — System Design

---

## 1. High-Level System Diagram

```
┌─────────────────────────────┐        ┌─────────────────────────────┐
│   Flutter Customer App      │        │   Flutter Admin Web Panel   │
│   (Android / iOS / Web)     │        │   (Web)                     │
└──────────────┬───────────────┘        └──────────────┬──────────────┘
               │  REST/GraphQL (HTTPS)                  │
               ▼                                         ▼
        ┌───────────────────────────────────────────────────────┐
        │                     NestJS API Gateway                 │
        │  Auth │ Catalog │ Cart │ Orders │ Payments │ Suppliers │
        └───────┬───────────────┬───────────────┬────────────────┘
                │               │               │
        ┌───────▼─────┐ ┌───────▼──────┐ ┌──────▼───────┐
        │ PostgreSQL   │ │   Redis      │ │  S3 Storage  │
        │ (primary DB) │ │ (cache/queue)│ │ (media)      │
        └──────────────┘ └──────────────┘ └──────────────┘
                │
        ┌───────▼─────────────────────────────┐
        │ External Integrations               │
        │ JazzCash / Easypaisa / Card gateway  │
        │ Firebase Cloud Messaging (push)      │
        │ Supplier feeds (CSV/API) — Phase 1    │
        └───────────────────────────────────────┘
```

---

## 2. Flutter App Architecture (Clean Architecture, feature-first)

```
lib/
 ├─ core/
 │   ├─ network/        (dio client, interceptors)
 │   ├─ theme/           (Material 3 theme, animations, tokens)
 │   ├─ routing/         (GoRouter config)
 │   ├─ widgets/         (shared UI components)
 │   └─ utils/
 │
 ├─ features/
 │   ├─ auth/
 │   │   ├─ data/        (models, repositories impl, remote/local sources)
 │   │   ├─ domain/      (entities, repository interfaces, usecases)
 │   │   └─ presentation/ (screens, Riverpod providers/notifiers, widgets)
 │   ├─ catalog/
 │   ├─ product_detail/
 │   ├─ cart/
 │   ├─ checkout/
 │   ├─ orders/
 │   ├─ wishlist/
 │   ├─ profile/
 │   ├─ notifications/
 │   └─ admin/               (separate app target sharing core/ + some features)
 │       ├─ dashboard/
 │       ├─ products/
 │       ├─ suppliers/
 │       ├─ orders_admin/
 │       └─ promotions/
 │
 └─ main_customer.dart / main_admin.dart   (two entry points, shared codebase)
```

**Key point:** Customer app and Admin panel are two build targets (`main_customer.dart`, `main_admin.dart`) sharing `core/` and reusable packages, so business logic (models, API client, theme tokens) isn't duplicated.

---

## 3. Backend Architecture (NestJS)

```
src/
 ├─ auth/            (OTP, JWT, social login)
 ├─ users/
 ├─ products/        (catalog, variants, categories)
 ├─ suppliers/        (Phase 1: supplier CRUD, stock/price sync jobs)
 ├─ inventory/        (stock levels — grows in Phase 2)
 ├─ cart/
 ├─ orders/           (order state machine, fulfillment_type routing)
 ├─ payments/         (JazzCash, Easypaisa, card gateway adapters)
 ├─ promotions/       (coupons, flash sales)
 ├─ notifications/    (FCM push, in-app inbox)
 ├─ reviews/
 └─ admin/            (RBAC guards, reporting/analytics endpoints)
```

**Fulfillment abstraction (core to the phase transition):**
Each `Product` has a `fulfillment_type` enum: `DROPSHIP` | `OWN_STOCK`. Each `Order Item` inherits this at time of purchase. Order routing logic checks this field to decide: notify supplier vs. deduct from own warehouse inventory. This means Phase 1 → Phase 2 → Phase 3 requires **no schema migration**, only data/config changes as products shift categories.

---

## 4. Core Database Schema (simplified)

```
users(id, name, phone, email, role, created_at)
addresses(id, user_id, label, address_line, city, is_default)

categories(id, name, parent_id)
products(id, name, description, category_id, fulfillment_type, base_price, images[], status)
product_variants(id, product_id, sku, size, color, price, stock_qty)

suppliers(id, name, contact_info, feed_type)
supplier_products(id, supplier_id, product_id, cost_price, sync_status)

carts(id, user_id, status)
cart_items(id, cart_id, variant_id, qty)

orders(id, user_id, status, payment_method, total, address_id, created_at)
order_items(id, order_id, variant_id, qty, price, fulfillment_type_snapshot)

payments(id, order_id, provider, status, transaction_ref)

reviews(id, product_id, user_id, rating, comment, images[])
coupons(id, code, discount_type, value, valid_from, valid_to)
notifications(id, user_id, title, body, type, read_at)
```

---

## 5. API Contract Overview (REST, versioned `/api/v1`)

| Domain | Key Endpoints |
|---|---|
| Auth | `POST /auth/otp/request`, `POST /auth/otp/verify`, `POST /auth/social` |
| Catalog | `GET /products`, `GET /products/:id`, `GET /categories` |
| Cart | `GET /cart`, `POST /cart/items`, `PATCH /cart/items/:id`, `DELETE /cart/items/:id` |
| Checkout | `POST /orders`, `GET /orders/:id`, `PATCH /orders/:id/cancel` |
| Payments | `POST /payments/initiate`, `POST /payments/webhook/:provider` |
| Admin — Products | `POST /admin/products`, `PATCH /admin/products/:id`, `POST /admin/products/import` |
| Admin — Suppliers | `GET /admin/suppliers`, `POST /admin/suppliers/:id/sync` |
| Admin — Orders | `PATCH /admin/orders/:id/status`, `POST /admin/orders/:id/assign-fulfillment` |
| Notifications | `POST /notifications/register-device`, `GET /notifications` |

Auth on all admin routes via JWT + RBAC guard (`Owner`, `Manager`, `Support`, `CatalogEditor`).

---

## 6. Scalability & Reliability Notes

- Redis-backed job queue (BullMQ) for: stock-sync from suppliers, push notification dispatch, order status webhooks
- Read-heavy catalog endpoints cached in Redis with short TTL + cache-busting on product update
- Horizontal scaling: stateless NestJS instances behind a load balancer; Postgres with read replica once traffic grows
- Payment webhooks are idempotent (transaction_ref dedup) to survive retries from JazzCash/Easypaisa

---

## 7. Next Deliverable
→ README (project setup, folder structure, run instructions) — then implementation scaffold begins.
