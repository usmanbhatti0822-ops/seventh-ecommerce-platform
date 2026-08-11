import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { JwtModule } from "@nestjs/jwt";
import { PassportModule } from "@nestjs/passport";
import { User } from "../entities/user.entity";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { OtpService } from "./otp.service";
import { SocialAuthService } from "./social-auth.service";
import { JwtStrategy } from "./jwt.strategy";
import { RolesGuard } from "./roles.guard";

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    PassportModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || "change_me",
      signOptions: { expiresIn: "7d" },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, OtpService, SocialAuthService, JwtStrategy, RolesGuard],
  exports: [AuthService, OtpService],
})
export class AuthModule {}
