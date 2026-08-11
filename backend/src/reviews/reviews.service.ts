import { Injectable, BadRequestException, NotFoundException } from "@nestjs/common";
import { InMemoryReviewsStore } from "./reviews.store";
import { CreateReviewDto } from "./dto/create-review.dto";

@Injectable()
export class ReviewsService {
  constructor(private readonly store: InMemoryReviewsStore) {}

  findAll(productId?: string) {
    return this.store.findAll(productId);
  }

  findOne(id: string) {
    const review = this.store.findOne(id);
    if (!review) throw new NotFoundException("Review not found");
    return review;
  }

  create(dto: CreateReviewDto) {
    if (!Number.isInteger(dto.rating) || dto.rating < 1 || dto.rating > 5) {
      throw new BadRequestException("Rating must be an integer between 1 and 5");
    }
    return this.store.create({
      productId: dto.productId,
      productName: dto.productName,
      rating: dto.rating,
      comment: dto.comment,
      reviewerName: dto.reviewerName,
      verifiedPurchase: dto.verifiedPurchase ?? false,
    });
  }
}
