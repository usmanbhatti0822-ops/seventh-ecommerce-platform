import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Order } from "../entities/order.entity";
import { OrderItem } from "../entities/order-item.entity";
import { Address } from "../entities/address.entity";
import { SupplierProduct } from "../entities/supplier-product.entity";
import { ProductVariant } from "../entities/product-variant.entity";
import { OrdersController } from "./orders.controller";
import { OrdersService } from "./orders.service";
import { FulfillmentService } from "./fulfillment.service";
import { CartModule } from "../cart/cart.module";

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem, Address, SupplierProduct, ProductVariant]),
    CartModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService, FulfillmentService],
  exports: [OrdersService],
})
export class OrdersModule {}
