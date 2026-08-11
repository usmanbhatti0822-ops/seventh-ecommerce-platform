import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { User } from "./user.entity";

@Entity("addresses")
export class Address {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @ManyToOne(() => User, (user) => user.addresses)
  user: User;

  @Column()
  label: string;

  @Column()
  addressLine: string;

  @Column()
  city: string;

  @Column({ default: false })
  isDefault: boolean;
}
