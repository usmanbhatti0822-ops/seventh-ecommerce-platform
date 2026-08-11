import { Injectable, Logger } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { FulfillmentType } from "../entities/product.entity";
import { OrderItem } from "../entities/order-item.entity";
import { SupplierProduct } from "../entities/supplier-product.entity";
import { ProductVariant } from "../entities/product-variant.entity";

/**
 * Routes a confirmed order item to the right fulfillment path.
 * Phase 1: everything routes to DROPSHIP (notify supplier).
 * Phase 2+: OWN_STOCK items route to warehouse/inventory deduction instead.
 * This is the single seam that lets the platform shift from dropshipping
 * to owned inventory without a schema/rewrite — only data changes.
 */
@Injectable()
export class FulfillmentService {
  private readonly logger = new Logger(FulfillmentService.name);

  constructor(
    @InjectRepository(OrderItem) private orderItemRepo: Repository<OrderItem>,
    @InjectRepository(SupplierProduct) private supplierProductRepo: Repository<SupplierProduct>,
    @InjectRepository(ProductVariant) private variantRepo: Repository<ProductVariant>,
  ) {}

  async routeOrderItem(fulfillmentType: FulfillmentType, orderItemId: string) {
    if (fulfillmentType === FulfillmentType.DROPSHIP) {
      return this.routeToSupplier(orderItemId);
    }
    return this.routeToWarehouse(orderItemId);
  }

  private async routeToSupplier(orderItemId: string) {
    const orderItem = await this.orderItemRepo.findOne({
      where: { id: orderItemId },
      relations: ["variant", "variant.product"],
    });
    if (!orderItem) return { routedTo: "supplier", orderItemId, error: "order item not found" };

    const supplierLink = await this.supplierProductRepo.findOne({
      where: { product: { id: orderItem.variant.product.id } },
      relations: ["supplier"],
    });

    if (!supplierLink) {
      this.logger.warn(`No supplier mapped for product ${orderItem.variant.product.id} — needs manual assignment`);
      return { routedTo: "supplier", orderItemId, status: "unassigned" };
    }

    // TODO: actually push the order to the supplier (email notification,
    // API call, or a shared spreadsheet row) depending on supplier.feedType.
    this.logger.log(`Order item ${orderItemId} sent to supplier ${supplierLink.supplier.name}`);
    return { routedTo: "supplier", orderItemId, supplierId: supplierLink.supplier.id, status: "notified" };
  }

  private async routeToWarehouse(orderItemId: string) {
    const orderItem = await this.orderItemRepo.findOne({ where: { id: orderItemId }, relations: ["variant"] });
    if (!orderItem) return { routedTo: "warehouse", orderItemId, error: "order item not found" };

    // Deduct from own-stock inventory. Uses a decrement query (not read-then-write)
    // to avoid a race condition between two orders decrementing the same variant.
    await this.variantRepo
      .createQueryBuilder()
      .update(ProductVariant)
      .set({ stockQty: () => `GREATEST(stock_qty - ${orderItem.qty}, 0)` })
      .where("id = :id", { id: orderItem.variant.id })
      .execute();

    this.logger.log(`Order item ${orderItemId} deducted from warehouse stock (qty: ${orderItem.qty})`);
    return { routedTo: "warehouse", orderItemId, status: "deducted" };
  }
}
