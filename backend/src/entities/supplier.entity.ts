import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";

@Entity("suppliers")
export class Supplier {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  contactInfo: string;

  @Column({ default: "manual" })
  feedType: string; // "manual" | "csv" | "api"
}
