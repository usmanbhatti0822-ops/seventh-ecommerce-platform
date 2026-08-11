import { CreateProductDto } from "./create-product.dto";

export class UpdateProductDto implements Partial<CreateProductDto> {
  name?: string;
  description?: string;
  categoryId?: string;
  fulfillmentType?: any;
  basePrice?: number;
  images?: string[];
}
