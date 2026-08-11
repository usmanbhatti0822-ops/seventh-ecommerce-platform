import { Injectable } from "@nestjs/common";
import { REVIEWS, MockReview, generateMockId } from "../common/mock-data";

/**
 * DEMO MODE: reviews live in memory, seeded with realistic ratings/comments —
 * there is no `reviews` table in `entities/` (only the 12 core commerce
 * entities exist; see the users/admin/notifications/promotions/inventory
 * stores for the same pattern). `ReviewsService` only depends on the methods
 * below, so this is a drop-in swap for a real `Repository<Review>` later.
 */
@Injectable()
export class InMemoryReviewsStore {
  private reviews: MockReview[] = REVIEWS.map((r) => ({ ...r }));

  findAll(productId?: string): MockReview[] {
    const list = productId ? this.reviews.filter((r) => r.productId === productId) : this.reviews;
    return [...list].sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }

  findOne(id: string): MockReview | undefined {
    return this.reviews.find((r) => r.id === id);
  }

  create(data: Omit<MockReview, "id" | "createdAt">): MockReview {
    const review: MockReview = {
      ...data,
      id: generateMockId("rev"),
      createdAt: new Date().toISOString(),
    };
    this.reviews.unshift(review);
    return review;
  }
}
