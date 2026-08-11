import { Controller, Get, Post, Patch, Param, Body, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { InventoryService } from "./inventory.service";
import { CreateInventoryRecordDto } from "./dto/create-inventory-record.dto";
import { RecordMovementDto } from "./dto/record-movement.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

/** Admin-only warehouse/stock screen — not part of the customer-facing storefront API. */
@Controller("inventory")
@UseGuards(AuthGuard("jwt"), RolesGuard)
@Roles("OWNER", "MANAGER", "CATALOG_EDITOR")
export class InventoryController {
  constructor(private readonly service: InventoryService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get("low-stock")
  findLowStock() {
    return this.service.findLowStock();
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateInventoryRecordDto) {
    return this.service.create(dto);
  }

  @Patch(":id/movements")
  recordMovement(@Param("id") id: string, @Body() dto: RecordMovementDto) {
    return this.service.recordMovement(id, dto);
  }
}
