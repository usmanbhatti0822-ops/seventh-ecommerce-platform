import { Injectable } from "@nestjs/common";
import { PROMOTIONS, MockPromotion, generateMockId } from "../common/mock-data";

/**
 * DEMO MODE: promotions/coupons live in memory — there is no `promotions`
 * table in `entities/` (only the 12 core commerce entities exist). See
 * `notifications.store.ts` for the same pattern and rationale.
 */
@Injectable()
export class InMemoryPromotionsStore {
  private promotions: MockPromotion[] = PROMOTIONS.map((p) => ({ ...p }));

  findAll(): MockPromotion[] {
    return [...this.promotions].sort((a, b) => (a.validFrom < b.validFrom ? 1 : -1));
  }

  findOne(id: string): MockPromotion | undefined {
    return this.promotions.find((p) => p.id === id);
  }

  findByCode(code: string): MockPromotion | undefined {
    return this.promotions.find((p) => p.code.toLowerCase() === code.toLowerCase());
  }

  create(data: Omit<MockPromotion, "id" | "usageCount">): MockPromotion {
    const promotion: MockPromotion = {
      ...data,
      id: generateMockId("promo"),
      usageCount: 0,
    };
    this.promotions.unshift(promotion);
    return promotion;
  }
}
