import { Module } from "@nestjs/common";
import { PromotionsController } from "./promotions.controller";
import { PromotionsService } from "./promotions.service";
import { InMemoryPromotionsStore } from "./promotions.store";

@Module({
  controllers: [PromotionsController],
  providers: [PromotionsService, InMemoryPromotionsStore],
  exports: [PromotionsService],
})
export class PromotionsModule {}
