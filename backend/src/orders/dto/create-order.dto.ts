export class CreateOrderDto {
  addressId: string;
  paymentMethod: "COD" | "JAZZCASH" | "EASYPAISA" | "CARD";
}
