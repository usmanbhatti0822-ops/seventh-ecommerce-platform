export class InitiatePaymentDto {
  orderId: string;
  provider: "COD" | "JAZZCASH" | "EASYPAISA" | "CARD";
  /** Required when provider is "CARD". Demo mode accepts any well-shaped card — see payments/adapters/card.adapter.ts. */
  card?: {
    number: string;
    expiryMonth: number;
    expiryYear: number;
    cvc: string;
    holderName?: string;
  };
}
