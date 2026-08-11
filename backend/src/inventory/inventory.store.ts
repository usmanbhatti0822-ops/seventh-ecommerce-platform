import { Injectable } from "@nestjs/common";
import { INVENTORY, MockInventoryRecord, StockMovement, generateMockId } from "../common/mock-data";

/**
 * DEMO MODE: stock records live in memory — there is no `inventory` table in
 * `entities/` (only the 12 core commerce entities exist; real stock levels
 * currently live on `ProductVariant.stockQty`). This store models the
 * richer warehouse/SKU-level view the admin "Inventory" screen wants
 * (PRD 4.2 — becomes central once Phase 2 / own-stock starts).
 */
@Injectable()
export class InMemoryInventoryStore {
  private records: MockInventoryRecord[] = INVENTORY.map((r) => ({ ...r, movements: [...r.movements] }));

  findAll(): MockInventoryRecord[] {
    return [...this.records];
  }

  findOne(id: string): MockInventoryRecord | undefined {
    return this.records.find((r) => r.id === id);
  }

  findLowStock(): MockInventoryRecord[] {
    return this.records.filter((r) => r.stockQty <= r.lowStockThreshold);
  }

  create(data: Omit<MockInventoryRecord, "id" | "movements">): MockInventoryRecord {
    const record: MockInventoryRecord = { ...data, id: generateMockId("inv"), movements: [] };
    this.records.unshift(record);
    return record;
  }

  recordMovement(id: string, movement: Omit<StockMovement, "id" | "occurredAt">): MockInventoryRecord | undefined {
    const record = this.findOne(id);
    if (!record) return undefined;
    record.movements.unshift({ ...movement, id: generateMockId("mv"), occurredAt: new Date().toISOString() });
    record.stockQty += movement.type === "in" ? movement.quantity : -movement.quantity;
    if (movement.type === "in") record.lastRestockedAt = new Date().toISOString();
    return record;
  }
}
