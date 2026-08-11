import { Injectable, BadRequestException, NotFoundException } from "@nestjs/common";
import { InMemoryInventoryStore } from "./inventory.store";
import { CreateInventoryRecordDto } from "./dto/create-inventory-record.dto";
import { RecordMovementDto } from "./dto/record-movement.dto";

@Injectable()
export class InventoryService {
  constructor(private readonly store: InMemoryInventoryStore) {}

  findAll() {
    return this.store.findAll();
  }

  findOne(id: string) {
    const record = this.store.findOne(id);
    if (!record) throw new NotFoundException("Inventory record not found");
    return record;
  }

  findLowStock() {
    return this.store.findLowStock();
  }

  create(dto: CreateInventoryRecordDto) {
    return this.store.create({
      sku: dto.sku,
      productName: dto.productName,
      variantLabel: dto.variantLabel,
      warehouseLocation: dto.warehouseLocation,
      stockQty: dto.stockQty,
      lowStockThreshold: dto.lowStockThreshold,
      lastRestockedAt: dto.lastRestockedAt ?? new Date().toISOString(),
    });
  }

  recordMovement(id: string, dto: RecordMovementDto) {
    if (dto.quantity <= 0) throw new BadRequestException("Quantity must be greater than 0");
    const record = this.store.recordMovement(id, dto);
    if (!record) throw new NotFoundException("Inventory record not found");
    return record;
  }
}
