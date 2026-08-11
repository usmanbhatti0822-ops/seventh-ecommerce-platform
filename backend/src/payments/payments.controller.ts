import { Controller, Post, Body, Param, UseGuards, Req } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { PaymentsService } from "./payments.service";
import { InitiatePaymentDto } from "./dto/initiate-payment.dto";

@Controller("payments")
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post("initiate")
  @UseGuards(AuthGuard("jwt"))
  initiate(@Body() dto: InitiatePaymentDto) {
    return this.paymentsService.initiate(dto);
  }

  @Post("cod/confirm/:paymentId")
  @UseGuards(AuthGuard("jwt"))
  confirmCod(@Param("paymentId") paymentId: string, @Body("code") code: string) {
    return this.paymentsService.confirmCodOtp(paymentId, code);
  }

  @Post("webhook/:provider")
  webhook(@Param("provider") provider: "jazzcash" | "easypaisa", @Body() payload: any) {
    return this.paymentsService.handleWebhook(provider, payload);
  }
}
