import { Controller, Get, Post, Patch, Param, Body, Req, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { NotificationsService } from "./notifications.service";
import { CreateNotificationDto } from "./dto/create-notification.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

@Controller("notifications")
@UseGuards(AuthGuard("jwt"))
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  /** The signed-in user's notification inbox (their own + any broadcast notifications). */
  @Get()
  findMine(@Req() req: any) {
    return this.service.findAll(req.user.userId);
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Patch(":id/read")
  markRead(@Param("id") id: string) {
    return this.service.markRead(id);
  }

  /** Notification composer — push a campaign to one user or broadcast to everyone. Admin only (PRD 4.2). */
  @Post()
  @UseGuards(RolesGuard)
  @Roles("OWNER", "MANAGER", "SUPPORT")
  create(@Body() dto: CreateNotificationDto) {
    return this.service.create(dto);
  }
}
