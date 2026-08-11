import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from "typeorm";
import { Address } from "./address.entity";
import { Order } from "./order.entity";

export enum UserRole {
  CUSTOMER = "CUSTOMER",
  OWNER = "OWNER",
  MANAGER = "MANAGER",
  SUPPORT = "SUPPORT",
  CATALOG_EDITOR = "CATALOG_EDITOR",
}

@Entity("users")
export class User {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ nullable: true })
  name: string;

  @Column({ unique: true })
  phone: string;

  @Column({ nullable: true, unique: true })
  email: string;

  @Column({ type: "enum", enum: UserRole, default: UserRole.CUSTOMER })
  role: UserRole;

  @Column({ nullable: true })
  socialProvider: string; // "google" | "apple" | null

  @Column({ nullable: true })
  socialProviderId: string;

  @OneToMany(() => Address, (address) => address.user)
  addresses: Address[];

  @OneToMany(() => Order, (order) => order.user)
  orders: Order[];

  @CreateDateColumn()
  createdAt: Date;
}
