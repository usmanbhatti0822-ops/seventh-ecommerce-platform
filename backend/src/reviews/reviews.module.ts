import { Module } from "@nestjs/common";
import { ReviewsController } from "./reviews.controller";
import { ReviewsService } from "./reviews.service";
import { InMemoryReviewsStore } from "./reviews.store";

@Module({
  controllers: [ReviewsController],
  providers: [ReviewsService, InMemoryReviewsStore],
  exports: [ReviewsService],
})
export class ReviewsModule {}
