import { Injectable } from "@nestjs/common";
import { NOTIFICATIONS, MockNotification, generateMockId } from "../common/mock-data";

/**
 * DEMO MODE: notifications live in memory, seeded with realistic data on
 * boot instead of being backed by a TypeORM entity — there is no
 * `notifications` table in this project (see `entities/` — only the 12
 * core commerce entities exist; a real notifications table would also need
 * an FCM delivery pipeline, which is out of scope for a portfolio demo).
 *
 * `NotificationsService` only talks to the methods below, so swapping this
 * for a real `Repository<Notification>` later is a drop-in change.
 */
@Injectable()
export class InMemoryNotificationsStore {
  private notifications: MockNotification[] = NOTIFICATIONS.map((n) => ({ ...n }));

  findAll(userId?: string): MockNotification[] {
    const list = userId
      ? this.notifications.filter((n) => n.userId === userId || n.userId === null)
      : this.notifications;
    return [...list].sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }

  findOne(id: string): MockNotification | undefined {
    return this.notifications.find((n) => n.id === id);
  }

  markRead(id: string): MockNotification | undefined {
    const notification = this.findOne(id);
    if (notification) notification.read = true;
    return notification;
  }

  create(data: Omit<MockNotification, "id" | "read" | "createdAt">): MockNotification {
    const notification: MockNotification = {
      ...data,
      id: generateMockId("notif"),
      read: false,
      createdAt: new Date().toISOString(),
    };
    this.notifications.unshift(notification);
    return notification;
  }
}
