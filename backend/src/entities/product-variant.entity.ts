import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { Product } from "./product.entity";

@Entity("product_variants")
export class ProductVariant {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => Product, (product) => product.variants)
  product: Product;

  @Column({ unique: true })
  sku: string;

  @Column({ nullable: true })
  size: string;

  @Column({ nullable: true })
  color: string;

  @Column("decimal", { precision: 10, scale: 2 })
  price: number;

  @Column({ default: 0 })
  stockQty: number;
}
