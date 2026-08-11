import { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Initial schema migration placeholder.
 * Generate the real version once DB connection is available:
 *   npx typeorm-ts-node-commonjs migration:generate -d src/data-source.ts src/migrations/InitSchema
 * This stub documents intent so the project is not blocked without a live DB.
 */
export class InitSchema1730000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // TODO: run migration:generate against a live Postgres instance to fill this in
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // TODO
  }
}
