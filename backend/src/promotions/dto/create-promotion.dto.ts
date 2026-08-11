import { DiscountType } from "../../common/mock-data";

export class CreatePromotionDto {
  code: string;
  description: string;
  discountType: DiscountType;
  discountValue: number;
  validFrom: string;
  validUntil: string;
  usageLimit?: number;
  active?: boolean;
}
