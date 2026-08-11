import { Controller, Get, Post, Patch, Param, Body, Req, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { OrdersService } from "./orders.service";
import { CreateOrderDto } from "./dto/create-order.dto";
import { OrderStatus } from "../entities/order.entity";
import { Roles, RolesGuard } from "../auth/roles.guard";

@Controller("orders")
@UseGuards(AuthGuard("jwt"))
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  findMine(@Req() req: any) {
    return this.ordersService.findAllForUser(req.user.userId);
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.ordersService.findOne(id);
  }

  @Post()
  create(@Req() req: any, @Body() dto: CreateOrderDto) {
    return this.ordersService.createFromCart(req.user.userId, dto);
  }

  @Patch(":id/cancel")
  cancel(@Req() req: any, @Param("id") id: string) {
    return this.ordersService.cancel(id, req.user.userId);
  }

  @Patch(":id/status")
  @UseGuards(RolesGuard)
  @Roles("OWNER", "MANAGER", "SUPPORT")
  updateStatus(@Param("id") id: string, @Body("status") status: OrderStatus) {
    return this.ordersService.updateStatus(id, status);
  }
}
