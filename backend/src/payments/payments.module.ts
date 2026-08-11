import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Payment } from "../entities/payment.entity";
import { Order } from "../entities/order.entity";
import { PaymentsController } from "./payments.controller";
import { PaymentsService } from "./payments.service";
import { AuthModule } from "../auth/auth.module";

@Module({
  imports: [TypeOrmModule.forFeature([Payment, Order]), AuthModule],
  controllers: [PaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
