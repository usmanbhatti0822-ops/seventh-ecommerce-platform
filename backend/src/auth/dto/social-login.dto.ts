export class SocialLoginDto {
  provider: "google" | "apple";
  idToken: string; // token issued by Google/Apple SDK on the Flutter client
}
