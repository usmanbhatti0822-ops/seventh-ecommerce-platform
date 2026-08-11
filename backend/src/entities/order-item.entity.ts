import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { Order } from "./order.entity";
import { ProductVariant } from "./product-variant.entity";
import { FulfillmentType } from "./product.entity";

@Entity("order_items")
export class OrderItem {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => Order, (order) => order.items)
  order: Order;

  @ManyToOne(() => ProductVariant)
  variant: ProductVariant;

  @Column()
  qty: number;

  @Column("decimal", { precision: 10, scale: 2 })
  price: number;

  @Column({ type: "enum", enum: FulfillmentType })
  fulfillmentTypeSnapshot: FulfillmentType;
}
