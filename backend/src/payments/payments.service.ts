import { Injectable, NotFoundException, BadRequestException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Payment, PaymentStatus } from "../entities/payment.entity";
import { Order, OrderStatus } from "../entities/order.entity";
import { JazzCashAdapter } from "./adapters/jazzcash.adapter";
import { EasypaisaAdapter } from "./adapters/easypaisa.adapter";
import { CardAdapter } from "./adapters/card.adapter";
import { InitiatePaymentDto } from "./dto/initiate-payment.dto";
import { OtpService } from "../auth/otp.service";

/** High-value COD orders require an OTP confirmation before dispatch, to cut down on fake/abusive COD orders. */
const COD_OTP_THRESHOLD_PKR = 5000;

@Injectable()
export class PaymentsService {
  private jazzCash = new JazzCashAdapter();
  private easypaisa = new EasypaisaAdapter();
  private card = new CardAdapter();

  constructor(
    @InjectRepository(Payment) private paymentRepo: Repository<Payment>,
    @InjectRepository(Order) private orderRepo: Repository<Order>,
    private otpService: OtpService,
  ) {}

  async initiate(dto: InitiatePaymentDto) {
    const order = await this.orderRepo.findOne({ where: { id: dto.orderId }, relations: ["user"] });
    if (!order) throw new NotFoundException("Order not found");

    const payment = this.paymentRepo.create({
      order,
      provider: dto.provider,
      status: PaymentStatus.PENDING,
    });

    if (dto.provider === "COD") {
      if (Number(order.total) >= COD_OTP_THRESHOLD_PKR) {
        // Send OTP to the order's phone to confirm high-value COD before it ships.
        const code = this.otpService.generateAndStore(order.user.phone);
        await this.paymentRepo.save(payment);
        return { requiresOtpConfirmation: true, devCode: code, paymentId: payment.id };
      }
      payment.status = PaymentStatus.SUCCESS; // COD is "confirmed" at order time, paid on delivery
      await this.paymentRepo.save(payment);
      return { requiresOtpConfirmation: false, payment };
    }

    if (dto.provider === "JAZZCASH") {
      const result = this.jazzCash.initiate(Number(order.total), order.id);
      payment.transactionRef = result.txnRefNo;
      await this.paymentRepo.save(payment);
      return result;
    }

    if (dto.provider === "EASYPAISA") {
      const result = this.easypaisa.initiate(Number(order.total), order.id);
      payment.transactionRef = result.txnRefNo;
      await this.paymentRepo.save(payment);
      return result;
    }

    if (dto.provider === "CARD") {
      if (!dto.card) throw new BadRequestException("Card details are required for CARD payments");
      const result = await this.card.authorize(Number(order.total), order.id, dto.card);
      payment.transactionRef = result.txnRefNo;
      payment.status = result.success ? PaymentStatus.SUCCESS : PaymentStatus.FAILED;
      await this.paymentRepo.save(payment);
      return result;
    }

    throw new BadRequestException(`Unsupported payment provider: ${dto.provider}`);
  }

  /** Customer confirms high-value COD via OTP sent to their phone. */
  async confirmCodOtp(paymentId: string, code: string) {
    const payment = await this.paymentRepo.findOne({ where: { id: paymentId }, relations: ["order", "order.user"] });
    if (!payment) throw new NotFoundException("Payment not found");
    const ok = this.otpService.verify(payment.order.user.phone, code);
    if (!ok) throw new BadRequestException("Invalid or expired OTP");
    payment.status = PaymentStatus.SUCCESS;
    return this.paymentRepo.save(payment);
  }

  async handleWebhook(provider: "jazzcash" | "easypaisa", payload: any) {
    const adapter = provider === "jazzcash" ? this.jazzCash : this.easypaisa;
    const valid = adapter.verifyWebhook(payload);
    if (!valid) throw new BadRequestException("Invalid webhook signature");

    const txnRefNo = payload.pp_TxnRefNo || payload.txnRefNo;
    // Idempotency: transactionRef has a unique DB constraint, so a duplicate
    // webhook delivery (common with payment gateways' at-least-once retries)
    // will simply match the existing row instead of creating a second payment.
    const payment = await this.paymentRepo.findOne({ where: { transactionRef: txnRefNo }, relations: ["order"] });
    if (!payment) throw new NotFoundException("Payment not found for transaction");

    const success = payload.pp_ResponseCode === "000" || payload.status === "success";
    payment.status = success ? PaymentStatus.SUCCESS : PaymentStatus.FAILED;
    await this.paymentRepo.save(payment);

    if (success) {
      payment.order.status = OrderStatus.CONFIRMED;
      await this.orderRepo.save(payment.order);
    }
    return { received: true };
  }
}
