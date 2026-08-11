import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from "typeorm";
import { Order } from "./order.entity";

export enum PaymentStatus {
  PENDING = "PENDING",
  SUCCESS = "SUCCESS",
  FAILED = "FAILED",
}

@Entity("payments")
export class Payment {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => Order)
  order: Order;

  @Column()
  provider: string; // "COD" | "JAZZCASH" | "EASYPAISA" | "CARD"

  @Column({ type: "enum", enum: PaymentStatus, default: PaymentStatus.PENDING })
  status: PaymentStatus;

  @Column({ unique: true, nullable: true })
  transactionRef: string; // used for webhook idempotency dedup

  @CreateDateColumn()
  createdAt: Date;
}
