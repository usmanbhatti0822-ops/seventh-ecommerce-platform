/** One row from a supplier's CSV stock/price feed. */
export class SupplierSyncRowDto {
  productId: string;
  costPrice: number;
  stockQty?: number;
}
