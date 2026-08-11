import { Injectable, Logger, UnauthorizedException } from "@nestjs/common";

interface SocialProfile {
  providerId: string;
  email?: string;
  name?: string;
}

/**
 * Verifies social login ID tokens from the Flutter client.
 *
 * DEMO MODE: this intentionally does not verify the token signature. Doing
 * so requires real OAuth client credentials (google-auth-library for
 * Google, JWKS verification against Apple's public keys for Apple) that
 * only exist once this app is registered with each provider — not
 * meaningful for a portfolio project without a live deployment. Instead it
 * derives a deterministic demo profile from the token string itself, so the
 * same input always logs in as the same demo user and the rest of the auth
 * flow (JWT issuance, user upsert) is exercised end-to-end.
 *
 * To go live: swap `verify()` for `google-auth-library`'s `OAuth2Client.verifyIdToken`
 * (Google) and JWKS-based verification of Apple's identity token, both of
 * which return a real, signature-checked `sub`/email/name.
 */
@Injectable()
export class SocialAuthService {
  private readonly logger = new Logger(SocialAuthService.name);
  private warned = false;

  async verify(provider: "google" | "apple", idToken: string): Promise<SocialProfile> {
    if (!idToken) {
      throw new UnauthorizedException("Missing idToken");
    }
    if (!this.warned) {
      this.logger.warn(
        "DEMO MODE: social login accepts any non-empty idToken without verifying its signature. See social-auth.service.ts before deploying for real.",
      );
      this.warned = true;
    }
    // Deterministic per-token demo identity — same token always maps to the same demo profile.
    const demoId = idToken.slice(0, 16);
    return {
      providerId: `${provider}-demo-${demoId}`,
      email: `${provider}.demo.${demoId}@example.com`,
      name: `${provider === "google" ? "Google" : "Apple"} Demo User`,
    };
  }
}
