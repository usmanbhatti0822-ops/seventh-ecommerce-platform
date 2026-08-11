import { Module } from "@nestjs/common";
import { AdminController } from "./admin.controller";
import { AdminService } from "./admin.service";
import { InMemoryStaffStore } from "./admin.store";
import { UsersModule } from "../users/users.module";

@Module({
  imports: [UsersModule],
  controllers: [AdminController],
  providers: [AdminService, InMemoryStaffStore],
  exports: [AdminService],
})
export class AdminModule {}
