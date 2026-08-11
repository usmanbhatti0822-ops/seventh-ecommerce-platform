import { Module } from "@nestjs/common";
import { InventoryController } from "./inventory.controller";
import { InventoryService } from "./inventory.service";
import { InMemoryInventoryStore } from "./inventory.store";

@Module({
  controllers: [InventoryController],
  providers: [InventoryService, InMemoryInventoryStore],
  exports: [InventoryService],
})
export class InventoryModule {}
