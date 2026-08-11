import { createHmac } from "crypto";

/**
 * JazzCash Mobile Wallet / Hosted Checkout adapter.
 * Docs: JazzCash integration requires a secure-hash (HMAC-SHA256) built from
 * a fixed field order using the merchant's integrity salt.
 *
 * DEMO MODE: `merchantId`/`password`/`integritySalt` are read from `.env`
 * but are empty by default (see `.env.example`) — this points at the
 * JazzCash *sandbox* URL and produces a validly-shaped, validly-hashed
 * request/redirect, it just isn't backed by a real merchant account. Drop
 * in real sandbox or production credentials from the JazzCash merchant
 * portal to make it fully functional; also re-confirm the exact field
 * order against the current JazzCash API guide before going live — the
 * hash breaks if the order is wrong.
 */
export class JazzCashAdapter {
  private merchantId = process.env.JAZZCASH_MERCHANT_ID || "";
  private password = process.env.JAZZCASH_PASSWORD || "";
  private integritySalt = process.env.JAZZCASH_INTEGRITY_SALT || "";

  initiate(amount: number, orderId: string) {
    const txnRefNo = `T${Date.now()}${orderId.slice(0, 6)}`;
    const params: Record<string, string> = {
      pp_Version: "1.1",
      pp_TxnType: "MWALLET",
      pp_MerchantID: this.merchantId,
      pp_Password: this.password,
      pp_TxnRefNo: txnRefNo,
      pp_Amount: String(Math.round(amount * 100)), // JazzCash expects amount in paisa
      pp_TxnCurrency: "PKR",
      pp_BillReference: orderId,
      pp_Description: `Order ${orderId}`,
    };
    const secureHash = this.buildSecureHash(params);
    return {
      redirectUrl: "https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform",
      params: { ...params, pp_SecureHash: secureHash },
      txnRefNo,
    };
  }

  private buildSecureHash(params: Record<string, string>): string {
    const sortedValues = Object.keys(params).sort().map((k) => params[k]).join("&");
    const hmac = createHmac("sha256", this.integritySalt);
    hmac.update(`${this.integritySalt}&${sortedValues}`);
    return hmac.digest("hex");
  }

  /** Verifies the pp_SecureHash on an inbound webhook/callback payload. */
  verifyWebhook(payload: Record<string, string>): boolean {
    const { pp_SecureHash, ...rest } = payload;
    return this.buildSecureHash(rest) === pp_SecureHash;
  }
}
