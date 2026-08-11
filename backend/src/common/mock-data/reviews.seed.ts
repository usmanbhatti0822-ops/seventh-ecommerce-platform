import { CUSTOMERS } from "./customers.seed";
import { daysAgo } from "./id.util";
import { MockReview } from "./types";

const c = CUSTOMERS;

/**
 * Product reviews. `productId` values are demo slugs matching the storefront's
 * editorial naming (see `app` home screen / `seed.ts` for the "Seventh" brand
 * voice) — they are not foreign keys into the `products` table, since reviews
 * have no backing entity in this demo (see module doc comment for why).
 */
export const REVIEWS: MockReview[] = [
  {
    id: "rev_001",
    productId: "prod_v2_hoodie_cloud",
    productName: "V2 Hoodie — Cloud",
    rating: 5,
    comment: "Heavier weight than I expected, in a good way. True to size, and the brushed interior is worth the price alone.",
    reviewerName: c[0].name,
    verifiedPurchase: true,
    createdAt: daysAgo(5),
  },
  {
    id: "rev_002",
    productId: "prod_v2_hoodie_cloud",
    productName: "V2 Hoodie — Cloud",
    rating: 4,
    comment: "Great fit and fabric, just wish there were more colourways in this cut.",
    reviewerName: c[4].name,
    verifiedPurchase: true,
    createdAt: daysAgo(18),
  },
  {
    id: "rev_003",
    productId: "prod_overdye_tee_charcoal",
    productName: "Overdye Tee — Charcoal",
    rating: 5,
    comment: "The overdye wash looks even better in person. Ordered a second one in Sand a week later.",
    reviewerName: c[7].name,
    verifiedPurchase: true,
    createdAt: daysAgo(9),
  },
  {
    id: "rev_004",
    productId: "prod_overdye_tee_charcoal",
    productName: "Overdye Tee — Charcoal",
    rating: 3,
    comment: "Fabric is nice but runs a bit small — order a size up.",
    reviewerName: c[1].name,
    verifiedPurchase: true,
    createdAt: daysAgo(30),
  },
  {
    id: "rev_005",
    productId: "prod_cargo_pant_olive",
    productName: "Cargo Pant — Olive",
    rating: 5,
    comment: "Pockets are actually usable, not just for show. Tapered leg without looking skinny.",
    reviewerName: c[2].name,
    verifiedPurchase: true,
    createdAt: daysAgo(12),
  },
  {
    id: "rev_006",
    productId: "prod_cargo_pant_olive",
    productName: "Cargo Pant — Olive",
    rating: 2,
    comment: "Waist ran big on me, had to return for an exchange. Sizing chart could be clearer.",
    reviewerName: c[9].name,
    verifiedPurchase: true,
    createdAt: daysAgo(40),
  },
  {
    id: "rev_007",
    productId: "prod_coach_jacket_ink",
    productName: "Coach Jacket — Ink",
    rating: 5,
    comment: "Best outerwear piece I own. The wind-resistant snap closures feel genuinely premium.",
    reviewerName: c[5].name,
    verifiedPurchase: true,
    createdAt: daysAgo(22),
  },
  {
    id: "rev_008",
    productId: "prod_coach_jacket_ink",
    productName: "Coach Jacket — Ink",
    rating: 4,
    comment: "Runs slightly long in the sleeve, but I actually like the oversized look.",
    reviewerName: c[8].name,
    verifiedPurchase: false,
    createdAt: daysAgo(3),
  },
  {
    id: "rev_009",
    productId: "prod_v2_hoodie_cloud",
    productName: "V2 Hoodie — Cloud",
    rating: 5,
    comment: "Cop it before it sells out again — VOL. 06 restocked once and sold out in a day.",
    reviewerName: c[10].name,
    verifiedPurchase: true,
    createdAt: daysAgo(2),
  },
  {
    id: "rev_010",
    productId: "prod_ribbed_beanie_black",
    productName: "Ribbed Beanie — Black",
    rating: 4,
    comment: "Simple, warm, and the woven tag doesn't feel cheap like most beanies at this price.",
    reviewerName: c[3].name,
    verifiedPurchase: true,
    createdAt: daysAgo(15),
  },
];
