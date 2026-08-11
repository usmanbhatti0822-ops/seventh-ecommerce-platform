import { Controller, Get, Post, Param, Body, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { SuppliersService } from "./suppliers.service";
import { CreateSupplierDto } from "./dto/create-supplier.dto";
import { SupplierSyncRowDto } from "./dto/sync-row.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

@Controller("suppliers")
@UseGuards(AuthGuard("jwt"), RolesGuard)
@Roles("OWNER", "MANAGER")
export class SuppliersController {
  constructor(private readonly suppliersService: SuppliersService) {}

  @Get()
  findAll() {
    return this.suppliersService.findAll();
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.suppliersService.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateSupplierDto) {
    return this.suppliersService.create(dto);
  }

  @Post(":id/sync")
  sync(@Param("id") id: string, @Body() rows: SupplierSyncRowDto[]) {
    return this.suppliersService.applySync(id, rows);
  }

  @Get(":id/sync-log")
  syncLog(@Param("id") id: string) {
    return this.suppliersService.syncLog(id);
  }
}
