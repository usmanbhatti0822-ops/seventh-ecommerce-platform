import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Supplier } from "../entities/supplier.entity";
import { SupplierProduct } from "../entities/supplier-product.entity";
import { ProductVariant } from "../entities/product-variant.entity";
import { SuppliersController } from "./suppliers.controller";
import { SuppliersService } from "./suppliers.service";
import { AuthModule } from "../auth/auth.module";

@Module({
  imports: [TypeOrmModule.forFeature([Supplier, SupplierProduct, ProductVariant]), AuthModule],
  controllers: [SuppliersController],
  providers: [SuppliersService],
  exports: [SuppliersService],
})
export class SuppliersModule {}
