import { Injectable, UnauthorizedException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { JwtService } from "@nestjs/jwt";
import { User, UserRole } from "../entities/user.entity";
import { OtpService } from "./otp.service";
import { SocialAuthService } from "./social-auth.service";
import { RequestOtpDto } from "./dto/request-otp.dto";
import { VerifyOtpDto } from "./dto/verify-otp.dto";
import { SocialLoginDto } from "./dto/social-login.dto";

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    private otpService: OtpService,
    private socialAuthService: SocialAuthService,
    private jwtService: JwtService,
  ) {}

  async requestOtp(dto: RequestOtpDto) {
    const code = this.otpService.generateAndStore(dto.phone);
    // In dev, return the code directly so the Flutter app can be tested end-to-end
    // without a live SMS gateway. Remove "devCode" before production.
    return { message: "OTP sent", devCode: code };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const ok = this.otpService.verify(dto.phone, dto.code);
    if (!ok) throw new UnauthorizedException("Invalid or expired OTP");

    let user = await this.usersRepo.findOne({ where: { phone: dto.phone } });
    if (!user) {
      user = this.usersRepo.create({ phone: dto.phone, role: UserRole.CUSTOMER });
      user = await this.usersRepo.save(user);
    }
    return this.issueToken(user);
  }

  async socialLogin(dto: SocialLoginDto) {
    const profile = await this.socialAuthService.verify(dto.provider, dto.idToken);

    let user = await this.usersRepo.findOne({
      where: { socialProvider: dto.provider, socialProviderId: profile.providerId },
    });
    if (!user) {
      user = this.usersRepo.create({
        socialProvider: dto.provider,
        socialProviderId: profile.providerId,
        email: profile.email,
        name: profile.name,
        role: UserRole.CUSTOMER,
        phone: `social-${profile.providerId}`, // placeholder until user adds real phone
      });
      user = await this.usersRepo.save(user);
    }
    return this.issueToken(user);
  }

  private issueToken(user: User) {
    const payload = { sub: user.id, role: user.role };
    return {
      accessToken: this.jwtService.sign(payload),
      user: { id: user.id, name: user.name, phone: user.phone, role: user.role },
    };
  }
}
