import { Injectable, BadRequestException, NotFoundException } from "@nestjs/common";
import { InMemoryPromotionsStore } from "./promotions.store";
import { CreatePromotionDto } from "./dto/create-promotion.dto";

@Injectable()
export class PromotionsService {
  constructor(private readonly store: InMemoryPromotionsStore) {}

  findAll() {
    return this.store.findAll();
  }

  findOne(id: string) {
    const promotion = this.store.findOne(id);
    if (!promotion) throw new NotFoundException("Promotion not found");
    return promotion;
  }

  create(dto: CreatePromotionDto) {
    if (this.store.findByCode(dto.code)) {
      throw new BadRequestException(`Promo code "${dto.code}" already exists`);
    }
    return this.store.create({
      code: dto.code.toUpperCase(),
      description: dto.description,
      discountType: dto.discountType,
      discountValue: dto.discountValue,
      validFrom: dto.validFrom,
      validUntil: dto.validUntil,
      usageLimit: dto.usageLimit ?? 0,
      active: dto.active ?? true,
    });
  }
}
