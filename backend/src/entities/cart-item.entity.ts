import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { Cart } from "./cart.entity";
import { ProductVariant } from "./product-variant.entity";

@Entity("cart_items")
export class CartItem {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => Cart, (cart) => cart.items)
  cart: Cart;

  @ManyToOne(() => ProductVariant)
  variant: ProductVariant;

  @Column({ default: 1 })
  qty: number;
}
