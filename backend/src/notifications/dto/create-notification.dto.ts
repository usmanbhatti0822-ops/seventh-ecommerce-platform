import { NotificationType } from "../../common/mock-data";

export class CreateNotificationDto {
  /** Omit or pass null to broadcast to every user (e.g. a flash-sale banner). */
  userId?: string | null;
  type: NotificationType;
  title: string;
  message: string;
}
