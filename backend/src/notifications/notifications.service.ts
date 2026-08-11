import { Injectable, NotFoundException } from "@nestjs/common";
import { InMemoryNotificationsStore } from "./notifications.store";
import { CreateNotificationDto } from "./dto/create-notification.dto";

@Injectable()
export class NotificationsService {
  constructor(private readonly store: InMemoryNotificationsStore) {}

  findAll(userId?: string) {
    return this.store.findAll(userId);
  }

  findOne(id: string) {
    const notification = this.store.findOne(id);
    if (!notification) throw new NotFoundException("Notification not found");
    return notification;
  }

  markRead(id: string) {
    const notification = this.store.markRead(id);
    if (!notification) throw new NotFoundException("Notification not found");
    return notification;
  }

  create(dto: CreateNotificationDto) {
    return this.store.create({
      userId: dto.userId ?? null,
      type: dto.type,
      title: dto.title,
      message: dto.message,
    });
  }
}
