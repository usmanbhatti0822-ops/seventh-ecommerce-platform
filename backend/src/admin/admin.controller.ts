import { Controller, Get, Post, Param, Body, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { AdminService } from "./admin.service";
import { CreateStaffDto } from "./dto/create-staff.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

/** Admin panel "Staff" (RBAC) screen + dashboard summary. Everything here is OWNER/MANAGER/SUPPORT territory. */
@Controller("admin")
@UseGuards(AuthGuard("jwt"), RolesGuard)
export class AdminController {
  constructor(private readonly service: AdminService) {}

  @Get()
  @Roles("OWNER", "MANAGER")
  findAll() {
    return this.service.findAll();
  }

  /** Revenue/orders/customers/top-products/recent-orders summary for the dashboard landing screen. */
  @Get("dashboard")
  @Roles("OWNER", "MANAGER", "SUPPORT")
  dashboard() {
    return this.service.getDashboard();
  }

  @Get(":id")
  @Roles("OWNER", "MANAGER")
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Post()
  @Roles("OWNER")
  create(@Body() dto: CreateStaffDto) {
    return this.service.create(dto);
  }
}
