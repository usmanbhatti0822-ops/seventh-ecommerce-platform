import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { Supplier } from "./supplier.entity";
import { Product } from "./product.entity";

@Entity("supplier_products")
export class SupplierProduct {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => Supplier)
  supplier: Supplier;

  @ManyToOne(() => Product)
  product: Product;

  @Column("decimal", { precision: 10, scale: 2 })
  costPrice: number;

  @Column({ default: "pending" })
  syncStatus: string;
}
