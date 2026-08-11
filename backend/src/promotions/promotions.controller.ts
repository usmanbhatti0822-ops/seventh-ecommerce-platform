import { Controller, Get, Post, Param, Body, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { PromotionsService } from "./promotions.service";
import { CreatePromotionDto } from "./dto/create-promotion.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

@Controller("promotions")
export class PromotionsController {
  constructor(private readonly service: PromotionsService) {}

  /** Active + past campaigns — the storefront filters to `active` client-side for the coupon field / banners. */
  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Post()
  @UseGuards(AuthGuard("jwt"), RolesGuard)
  @Roles("OWNER", "MANAGER")
  create(@Body() dto: CreatePromotionDto) {
    return this.service.create(dto);
  }
}
