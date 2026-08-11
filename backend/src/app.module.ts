import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { allEntities } from "./entities";
import { AuthModule } from "./auth/auth.module";
import { UsersModule } from "./users/users.module";
import { ProductsModule } from "./products/products.module";
import { SuppliersModule } from "./suppliers/suppliers.module";
import { InventoryModule } from "./inventory/inventory.module";
import { CartModule } from "./cart/cart.module";
import { OrdersModule } from "./orders/orders.module";
import { PaymentsModule } from "./payments/payments.module";
import { PromotionsModule } from "./promotions/promotions.module";
import { NotificationsModule } from "./notifications/notifications.module";
import { ReviewsModule } from "./reviews/reviews.module";
import { AdminModule } from "./admin/admin.module";

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: "postgres",
      url: process.env.DATABASE_URL || "postgres://user:pass@localhost:5432/ecommerce",
      entities: allEntities,
      synchronize: process.env.NODE_ENV !== "production", // dev convenience; use migrations in prod
      autoLoadEntities: true,
    }),
    AuthModule,
    UsersModule,
    ProductsModule,
    SuppliersModule,
    InventoryModule,
    CartModule,
    OrdersModule,
    PaymentsModule,
    PromotionsModule,
    NotificationsModule,
    ReviewsModule,
    AdminModule,
  ],
})
export class AppModule {}
