import "reflect-metadata";
import { DataSource } from "typeorm";
import { allEntities } from "./entities";

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL || "postgres://user:pass@localhost:5432/ecommerce",
  entities: allEntities,
  migrations: ["dist/migrations/*.js"],
  synchronize: false,
  logging: false,
});
