import { User } from "./user.entity";
import { Address } from "./address.entity";
import { Category } from "./category.entity";
import { Product } from "./product.entity";
import { ProductVariant } from "./product-variant.entity";
import { Supplier } from "./supplier.entity";
import { SupplierProduct } from "./supplier-product.entity";
import { Cart } from "./cart.entity";
import { CartItem } from "./cart-item.entity";
import { Order } from "./order.entity";
import { OrderItem } from "./order-item.entity";
import { Payment } from "./payment.entity";

export * from "./user.entity";
export * from "./address.entity";
export * from "./category.entity";
export * from "./product.entity";
export * from "./product-variant.entity";
export * from "./supplier.entity";
export * from "./supplier-product.entity";
export * from "./cart.entity";
export * from "./cart-item.entity";
export * from "./order.entity";
export * from "./order-item.entity";
export * from "./payment.entity";

/** Explicit entity class list for TypeOrmModule.forRoot / DataSource config (avoids picking up enums from barrel exports). */
export const allEntities = [
  User, Address, Category, Product, ProductVariant,
  Supplier, SupplierProduct, Cart, CartItem, Order, OrderItem, Payment,
];
