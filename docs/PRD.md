# Product Requirements Document (PRD)
## Flutter-Based E-Commerce Platform (Web + Mobile)

**Prepared for:** Usman
**Market:** Pakistan / South Asia
**Version:** 1.0

---

## 1. Vision & Phasing

A single Flutter codebase (web + Android + iOS) powering an e-commerce platform that launches as a **dropshipping store** and evolves into a **self-owned inventory / branded products store** — without needing a rewrite.

| Phase | Model | Goal |
|---|---|---|
| **Phase 1** | Dropshipping | Validate market, get orders flowing, zero/low inventory risk, build brand + customer base |
| **Phase 2** | Hybrid | Best-selling dropship SKUs get moved in-house; own warehouse/stock begins alongside dropship catalog |
| **Phase 3** | Own Products | Full in-house inventory, own manufacturing/sourcing, dropshipping phased out or kept as a supplementary catalog |

**Key architecture decision:** because the ordering, catalog, and inventory logic will be built around a `fulfillment_type` (dropship vs. own-stock) per product/order from day one, moving between phases is a **configuration change, not a rebuild**.

---

## 2. Platforms

- **Mobile app:** Flutter (Android + iOS) — Material 3
- **Website:** Flutter Web (same codebase, responsive breakpoints — not a separate web stack)
- **Admin Panel:** Flutter Web (separate app target, same shared packages — desktop-first responsive layout)
- **Backend:** NestJS + PostgreSQL (as per existing stack)

Using one Flutter codebase for mobile + web means shared business logic, shared design system, and shared state management (Riverpod) across all surfaces — one team, one release cadence.

---

## 3. User Roles

1. **Customer** — browses, buys, tracks orders
2. **Admin / Owner** — manages catalog, orders, suppliers, pricing, promotions, analytics
3. **Supplier/Vendor (Phase 1-2)** — dropship supplier data feed (manual or API-based) feeding into catalog/stock
4. **Delivery/Rider (optional, Phase 2+)** — if self-fulfillment is added later for owned products
5. **Support Agent (optional)** — handles customer queries/returns

---

## 4. Core Features

### 4.1 Customer App/Website
- Onboarding: phone/email OTP login, social login (Google/Apple), guest browsing
- Home: banners/carousel, flash sales countdown, personalized recommendations, category grid
- Product catalog: categories, subcategories, filters (price, brand, rating, size/color), sorting
- Product detail: image gallery + zoom, variant selection (size/color), stock status, reviews & ratings, "customers also bought"
- Search: instant search, search suggestions, recent searches, voice search (stretch)
- Cart: persistent cart, quantity edit, save-for-later, coupon/promo code field
- Checkout: multiple addresses, shipping method selection, order summary, guest checkout
- **Payments:** Cash on Delivery (critical for Pakistan), JazzCash, Easypaisa, bank transfer, card (Stripe/PayFast/HBL), wallet/store credit
- Order tracking: status timeline (placed → confirmed → shipped → out for delivery → delivered), push notifications per status
- Order history & reinvoicing, return/refund request flow
- Wishlist / favorites
- Reviews & ratings with photo upload
- Notifications: push, in-app inbox, order/promo alerts
- Loyalty/rewards points (Phase 2 stretch)
- Referral program (stretch)
- Live chat / support chat (stretch)
- Multi-language: English + Urdu; multi-currency ready (PKR primary)
- Dark mode

### 4.2 Admin Panel (Web)
- Dashboard: sales, orders, revenue, top products, customer growth (charts)
- Product management: add/edit/bulk-import (CSV), variants, media, SEO fields
- **Dropship supplier management (Phase 1 critical):** supplier list, per-supplier product mapping, cost price vs. sell price margin rules, auto price-sync, stock-sync (manual/API/CSV feed)
- Order management: status updates, assign to supplier for fulfillment (Phase 1) or warehouse (Phase 2+), print invoices/labels
- Inventory management: stock levels, low-stock alerts (becomes central once Phase 2 starts)
- Customer management: view customer, order history, block/flag
- Promotions: coupons, flash sales, bundle deals, banner scheduling
- Reports/analytics: sales by category, supplier performance, return rate
- Staff/roles management (RBAC): owner, manager, support, catalog editor
- CMS: homepage banners, static pages (About, Policy, T&C)
- Notification composer: push campaigns, segment targeting

### 4.3 Cross-cutting / Platform Features
- Modern, animated UI: smooth page transitions, skeleton loaders, micro-interactions on add-to-cart/like/checkout, hero animations on product images
- Responsive layout: same codebase adapts from mobile → tablet → desktop web
- Offline-friendly cart (local cache + sync)
- Deep linking (product/category/promo links open directly in-app)
- Analytics integration (Firebase Analytics / Mixpanel)
- Crash reporting (Sentry/Firebase Crashlytics)
- SEO for Flutter Web storefront (meta tags, pre-rendering strategy)

---

## 5. Tech Stack

| Layer | Choice |
|---|---|
| Mobile + Web UI | Flutter (Material 3), single codebase |
| State Management | Riverpod |
| Routing | GoRouter |
| Architecture | Clean Architecture, feature-first structure |
| Backend | NestJS |
| Database | PostgreSQL |
| Cache/Queue | Redis (cart sessions, stock-sync jobs, notification queue) |
| Media Storage | S3-compatible bucket (product images/videos) |
| Search | PostgreSQL full-text search initially → Meilisearch/Algolia if scale demands |
| Payments | JazzCash / Easypaisa APIs, COD, Stripe or PayFast for cards |
| Push Notifications | Firebase Cloud Messaging |
| Admin Charts | fl_chart (Flutter) |
| CI/CD | GitHub Actions |

---

## 6. Non-Functional Requirements

- App cold start < 2.5s; smooth 60fps animations
- Checkout flow must work reliably on low-end Android devices (common in target market)
- COD order abuse protection (OTP confirmation on high-value COD orders)
- PKR pricing precision, tax/GST fields ready
- Scalable to handle flash-sale traffic spikes
- Data privacy: customer data stored per Pakistani data-handling norms

---

## 7. Success Metrics (Phase 1)

- Time from order to supplier fulfillment
- Cart abandonment rate
- COD confirmation rate
- Repeat purchase rate (signals readiness to move products in-house for Phase 2)

---

## 8. Out of Scope (for v1)

- Own warehouse/inventory automation (comes in Phase 2)
- Own delivery fleet (Phase 2+/3)
- International shipping
- Marketplace (multi-seller) mode

---

## 9. Next Deliverables

1. **Design Flow** — user flow diagrams (customer journey, admin journey, order lifecycle)
2. **Architecture Document** — system architecture, DB schema outline, API contract overview
3. **README** — project setup, folder structure, run instructions
4. Then implementation start: project scaffold (Flutter app + NestJS backend)
