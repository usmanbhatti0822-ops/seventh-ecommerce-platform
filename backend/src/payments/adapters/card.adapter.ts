import { randomUUID } from "crypto";

interface CardDetails {
  number: string;
  expiryMonth: number;
  expiryYear: number;
  cvc: string;
  holderName?: string;
}

/**
 * Demo/sandbox-shaped card adapter — same `initiate`/`verifyWebhook` interface
 * as `JazzCashAdapter`/`EasypaisaAdapter` so `PaymentsService` treats all
 * providers uniformly. Not wired to a real merchant account: there is no
 * Stripe/PayFast API call here, just a simulated authorization so the card
 * checkout path is fully exercisable in a demo without real card data or a
 * live payment gateway account.
 *
 * To go live: replace `authorize()` with a real Stripe PaymentIntent (or
 * PayFast) call using a secret key from `.env`, and verify webhooks against
 * the provider's signing secret instead of `verifyWebhook`'s no-op check.
 */
export class CardAdapter {
  /** Well-known card-network test number for a guaranteed decline, so the failure path is demoable too. */
  private static readonly TEST_DECLINE_NUMBER = "4000000000000002";

  async authorize(amount: number, orderId: string, card: CardDetails) {
    // Simulate real gateway latency instead of resolving instantly.
    await new Promise((resolve) => setTimeout(resolve, 400 + Math.random() * 400));

    const txnRefNo = `CARD${Date.now()}${randomUUID().slice(0, 6)}`;
    const sanitizedNumber = (card?.number || "").replace(/\s+/g, "");
    const declined = sanitizedNumber === CardAdapter.TEST_DECLINE_NUMBER;

    if (declined) {
      return {
        success: false,
        txnRefNo,
        message: "Card declined by issuing bank (demo test card).",
        last4: sanitizedNumber.slice(-4),
      };
    }

    return {
      success: true,
      txnRefNo,
      authorizationCode: `AUTH-${randomUUID().slice(0, 8).toUpperCase()}`,
      amount,
      orderId,
      last4: sanitizedNumber.slice(-4) || "0000",
      message: "Payment authorized (demo mode — no real charge was made).",
    };
  }

  /** No real gateway sends webhooks in demo mode; card payments resolve synchronously via `authorize()` instead. */
  verifyWebhook(_payload: Record<string, string>): boolean {
    return true;
  }
}
