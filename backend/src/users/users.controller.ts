import { Controller, Get, Post, Param, Body, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { UsersService } from "./users.service";
import { CreateCustomerDto } from "./dto/create-customer.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

/** Admin panel "Customers" directory — see `users.store.ts` for how this relates to the real auth `User` entity. */
@Controller("users")
@UseGuards(AuthGuard("jwt"), RolesGuard)
@Roles("OWNER", "MANAGER", "SUPPORT")
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateCustomerDto) {
    return this.service.create(dto);
  }
}
