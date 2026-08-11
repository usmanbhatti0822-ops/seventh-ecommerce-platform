import { createHash } from "crypto";

/**
 * Easypaisa Open API (Mobile Account / Store) adapter.
 *
 * DEMO MODE: `storeId`/`hashKey` are read from `.env` but are empty by
 * default (see `.env.example`) — this points at the Easypaisa *sandbox*
 * URL and produces a validly-shaped, validly-hashed request, it just isn't
 * backed by a real merchant account. Drop in real sandbox or production
 * credentials to make it fully functional; also confirm the exact
 * request/response contract with the current Easypaisa merchant
 * integration guide before going live — field names vary between their
 * "Open API" and "InstaPay" products.
 */
export class EasypaisaAdapter {
  private storeId = process.env.EASYPAISA_STORE_ID || "";
  private hashKey = process.env.EASYPAISA_HASH_KEY || "";

  initiate(amount: number, orderId: string) {
    const txnRefNo = `EP${Date.now()}`;
    const payload = {
      storeId: this.storeId,
      orderId,
      amount: amount.toFixed(2),
      txnRefNo,
    };
    return {
      redirectUrl: "https://sandbox.easypaisa.com.pk/easypay/Index.jsf",
      params: { ...payload, hash: this.buildHash(payload) },
      txnRefNo,
    };
  }

  private buildHash(payload: Record<string, string>): string {
    const raw = Object.values(payload).join("|") + this.hashKey;
    return createHash("sha256").update(raw).digest("hex");
  }

  verifyWebhook(payload: Record<string, string>): boolean {
    const { hash, ...rest } = payload;
    return this.buildHash(rest) === hash;
  }
}
