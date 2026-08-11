import { Injectable, Logger } from "@nestjs/common";

interface OtpRecord {
  code: string;
  expiresAt: number;
}

/**
 * In-memory OTP store for now — swap for Redis (with TTL) once wired up,
 * so OTPs survive across multiple backend instances.
 *
 * DEMO MODE: the generated code is returned directly to the caller (see
 * `devCode` in `AuthService.requestOtp` / `PaymentsService.initiate`)
 * instead of being sent via SMS, so the app is fully testable end-to-end
 * without a live SMS gateway or per-message cost. Swap `generateAndStore`
 * for a real provider (Twilio, Telenor/Zong SMS API) before production —
 * at that point stop returning `devCode` from the API response too.
 */
@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  private store = new Map<string, OtpRecord>();
  private warned = false;

  generateAndStore(phone: string): string {
    const code = Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit OTP
    this.store.set(phone, { code, expiresAt: Date.now() + 5 * 60 * 1000 });
    if (!this.warned) {
      this.logger.warn(
        "DEMO MODE: OTPs are not sent via SMS — they're returned in the API response (devCode) so the app is testable without a live SMS gateway.",
      );
      this.warned = true;
    }
    return code;
  }

  verify(phone: string, code: string): boolean {
    const record = this.store.get(phone);
    if (!record) return false;
    if (Date.now() > record.expiresAt) {
      this.store.delete(phone);
      return false;
    }
    const valid = record.code === code;
    if (valid) this.store.delete(phone);
    return valid;
  }
}
