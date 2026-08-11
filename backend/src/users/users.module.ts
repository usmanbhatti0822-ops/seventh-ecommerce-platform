import { Module } from "@nestjs/common";
import { UsersController } from "./users.controller";
import { UsersService } from "./users.service";
import { InMemoryCustomersStore } from "./users.store";

@Module({
  controllers: [UsersController],
  providers: [UsersService, InMemoryCustomersStore],
  exports: [UsersService],
})
export class UsersModule {}
