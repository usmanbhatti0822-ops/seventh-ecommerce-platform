import { FulfillmentType } from "../../entities/product.entity";

export class CreateProductDto {
  name: string;
  description?: string;
  categoryId?: string;
  fulfillmentType?: FulfillmentType;
  basePrice: number;
  images?: string[];
  variants?: { sku: string; size?: string; color?: string; price: number; stockQty: number }[];
}
