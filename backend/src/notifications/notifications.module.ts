import { Module } from "@nestjs/common";
import { NotificationsController } from "./notifications.controller";
import { NotificationsService } from "./notifications.service";
import { InMemoryNotificationsStore } from "./notifications.store";

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, InMemoryNotificationsStore],
  exports: [NotificationsService],
})
export class NotificationsModule {}
