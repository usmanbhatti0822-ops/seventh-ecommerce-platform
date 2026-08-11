import { Controller, Get, Post, Patch, Delete, Param, Body, Req, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { CartService } from "./cart.service";
import { AddCartItemDto } from "./dto/add-item.dto";

@Controller("cart")
@UseGuards(AuthGuard("jwt"))
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get()
  getCart(@Req() req: any) {
    return this.cartService.getOrCreateActiveCart(req.user.userId);
  }

  @Post("items")
  addItem(@Req() req: any, @Body() dto: AddCartItemDto) {
    return this.cartService.addItem(req.user.userId, dto);
  }

  @Patch("items/:id")
  updateItem(@Req() req: any, @Param("id") id: string, @Body("qty") qty: number) {
    return this.cartService.updateItemQty(req.user.userId, id, qty);
  }

  @Delete("items/:id")
  removeItem(@Req() req: any, @Param("id") id: string) {
    return this.cartService.removeItem(req.user.userId, id);
  }
}
