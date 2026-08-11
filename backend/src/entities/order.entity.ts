import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, CreateDateColumn } from "typeorm";
import { User } from "./user.entity";
import { Address } from "./address.entity";
import { OrderItem } from "./order-item.entity";

export enum OrderStatus {
  PLACED = "PLACED",
  CONFIRMED = "CONFIRMED",
  SHIPPED = "SHIPPED",
  OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY",
  DELIVERED = "DELIVERED",
  CANCELLED = "CANCELLED",
  RETURN_REQUESTED = "RETURN_REQUESTED",
  REFUNDED = "REFUNDED",
}

@Entity("orders")
export class Order {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => User, (user) => user.orders)
  user: User;

  @Column({ type: "enum", enum: OrderStatus, default: OrderStatus.PLACED })
  status: OrderStatus;

  @Column()
  paymentMethod: string; // "COD" | "JAZZCASH" | "EASYPAISA" | "CARD"

  @Column("decimal", { precision: 10, scale: 2 })
  total: number;

  @ManyToOne(() => Address)
  address: Address;

  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
  items: OrderItem[];

  @CreateDateColumn()
  createdAt: Date;
}
