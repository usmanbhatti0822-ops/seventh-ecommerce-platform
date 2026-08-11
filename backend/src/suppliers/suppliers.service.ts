import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Supplier } from "../entities/supplier.entity";
import { SupplierProduct } from "../entities/supplier-product.entity";
import { ProductVariant } from "../entities/product-variant.entity";
import { CreateSupplierDto } from "./dto/create-supplier.dto";
import { SupplierSyncRowDto } from "./dto/sync-row.dto";

@Injectable()
export class SuppliersService {
  constructor(
    @InjectRepository(Supplier) private supplierRepo: Repository<Supplier>,
    @InjectRepository(SupplierProduct) private supplierProductRepo: Repository<SupplierProduct>,
    @InjectRepository(ProductVariant) private variantRepo: Repository<ProductVariant>,
  ) {}

  findAll() {
    return this.supplierRepo.find();
  }

  async findOne(id: string) {
    const supplier = await this.supplierRepo.findOne({ where: { id } });
    if (!supplier) throw new NotFoundException("Supplier not found");
    return supplier;
  }

  create(dto: CreateSupplierDto) {
    const supplier = this.supplierRepo.create(dto);
    return this.supplierRepo.save(supplier);
  }

  /**
   * Applies a batch of stock/price rows from a supplier feed (CSV parsed
   * client-side or on the admin panel, then posted here as JSON — keeps this
   * endpoint feed-format-agnostic; CSV parsing lives at the edge).
   * Phase 1 = manual CSV upload. Phase 1.5 = scheduled API pull, same method reused.
   */
  async applySync(supplierId: string, rows: SupplierSyncRowDto[]) {
    const supplier = await this.findOne(supplierId);
    let updated = 0;
    let created = 0;

    for (const row of rows) {
      let link = await this.supplierProductRepo.findOne({
        where: { supplier: { id: supplierId }, product: { id: row.productId } },
        relations: ["product"],
      });

      if (!link) {
        link = this.supplierProductRepo.create({
          supplier,
          product: { id: row.productId } as any,
          costPrice: row.costPrice,
          syncStatus: "synced",
        });
        created++;
      } else {
        link.costPrice = row.costPrice;
        link.syncStatus = "synced";
        updated++;
      }
      await this.supplierProductRepo.save(link);

      if (row.stockQty !== undefined) {
        // Push stock to all variants of this product from this supplier feed.
        // TODO: once variant-level supplier feeds exist, match by SKU instead of product-wide.
        await this.variantRepo
          .createQueryBuilder()
          .update(ProductVariant)
          .set({ stockQty: row.stockQty })
          .where("productId = :productId", { productId: row.productId })
          .execute();
      }
    }

    return { supplierId, created, updated, total: rows.length };
  }

  async syncLog(supplierId: string) {
    return this.supplierProductRepo.find({
      where: { supplier: { id: supplierId } },
      relations: ["product"],
    });
  }
}
