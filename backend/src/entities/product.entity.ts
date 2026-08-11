import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, CreateDateColumn } from "typeorm";
import { Category } from "./category.entity";
import { ProductVariant } from "./product-variant.entity";

export enum FulfillmentType {
  DROPSHIP = "DROPSHIP",
  OWN_STOCK = "OWN_STOCK",
}

export enum ProductStatus {
  DRAFT = "DRAFT",
  ACTIVE = "ACTIVE",
  ARCHIVED = "ARCHIVED",
}

@Entity("products")
export class Product {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  name: string;

  @Column({ type: "text", nullable: true })
  description: string;

  @ManyToOne(() => Category, { nullable: true })
  category: Category;

  @Column({ type: "enum", enum: FulfillmentType, default: FulfillmentType.DROPSHIP })
  fulfillmentType: FulfillmentType;

  @Column("decimal", { precision: 10, scale: 2 })
  basePrice: number;

  @Column("text", { array: true, default: [] })
  images: string[];

  @Column({ type: "enum", enum: ProductStatus, default: ProductStatus.DRAFT })
  status: ProductStatus;

  @OneToMany(() => ProductVariant, (variant) => variant.product)
  variants: ProductVariant[];

  @CreateDateColumn()
  createdAt: Date;
}
