export class CreateInventoryRecordDto {
  sku: string;
  productName: string;
  variantLabel?: string;
  warehouseLocation: string;
  stockQty: number;
  lowStockThreshold: number;
  lastRestockedAt?: string;
}
