import "reflect-metadata";
import { AppDataSource } from "./data-source";
import { User, UserRole } from "./entities/user.entity";
import { Address } from "./entities/address.entity";
import { Category } from "./entities/category.entity";
import { Product, FulfillmentType, ProductStatus } from "./entities/product.entity";
import { ProductVariant } from "./entities/product-variant.entity";
import { Supplier } from "./entities/supplier.entity";
import { SupplierProduct } from "./entities/supplier-product.entity";
import { Order, OrderStatus } from "./entities/order.entity";
import { OrderItem } from "./entities/order-item.entity";
import { Payment, PaymentStatus } from "./entities/payment.entity";

/**
 * Seeds temporary/demo data so the app and admin panel have something
 * realistic to show before real customers/orders exist: sample categories,
 * products with variants, customers, suppliers, and a spread of past orders
 * (\"sales\") across the last 30 days so the Dashboard/Reports charts have
 * real numbers to render instead of hardcoded mock arrays.
 *
 * Run with: npm run seed
 * Safe to re-run — it clears previously seeded rows (by a fixed marker
 * category/supplier name) before inserting fresh ones.
 */

const CATEGORY_NAMES = ["Fashion", "Electronics", "Home", "Beauty", "Kids"];

const PRODUCT_TEMPLATES = [
  { name: "Classic Cotton Kurta", category: "Fashion", price: 1899 },
  { name: "Embroidered Lawn Suit", category: "Fashion", price: 3499 },
  { name: "Men's Denim Jacket", category: "Fashion", price: 4299 },
  { name: "Wireless Earbuds Pro", category: "Electronics", price: 5999 },
  { name: "Power Bank 20000mAh", category: "Electronics", price: 3299 },
  { name: "Smart Watch Series X", category: "Electronics", price: 8999 },
  { name: "Non-Stick Cookware Set", category: "Home", price: 6499 },
  { name: "Cotton Bedsheet Set (King)", category: "Home", price: 2799 },
  { name: "LED Table Lamp", category: "Home", price: 1599 },
  { name: "Matte Lipstick Combo", category: "Beauty", price: 1299 },
  { name: "Vitamin C Serum", category: "Beauty", price: 1799 },
  { name: "Hair Styling Kit", category: "Beauty", price: 2499 },
  { name: "Kids Building Blocks Set", category: "Kids", price: 1999 },
  { name: "Toddler Winter Jacket", category: "Kids", price: 2299 },
  { name: "Educational Tablet for Kids", category: "Kids", price: 7499 },
];

const CUSTOMER_NAMES = [
  "Ayesha Khan", "Bilal Ahmed", "Sana Malik", "Hamza Tariq", "Zainab Raza",
  "Usman Farooq", "Mahnoor Iqbal", "Ali Hassan", "Fatima Sheikh", "Omar Siddiqui",
];

async function seed() {
  const ds = await AppDataSource.initialize();
  console.log("Connected to DB, seeding...");

  const userRepo = ds.getRepository(User);
  const addressRepo = ds.getRepository(Address);
  const categoryRepo = ds.getRepository(Category);
  const productRepo = ds.getRepository(Product);
  const variantRepo = ds.getRepository(ProductVariant);
  const supplierRepo = ds.getRepository(Supplier);
  const supplierProductRepo = ds.getRepository(SupplierProduct);
  const orderRepo = ds.getRepository(Order);
  const orderItemRepo = ds.getRepository(OrderItem);
  const paymentRepo = ds.getRepository(Payment);

  // ---------- Categories ----------
  const categories: Record<string, Category> = {};
  for (const name of CATEGORY_NAMES) {
    let cat = await categoryRepo.findOne({ where: { name } });
    if (!cat) cat = await categoryRepo.save(categoryRepo.create({ name }));
    categories[name] = cat;
  }
  console.log(`✔ ${CATEGORY_NAMES.length} categories ready`);

  // ---------- Suppliers ----------
  const supplierNames = ["Lahore Textile Traders", "Karachi Electronics Hub", "Faisalabad Home Essentials"];
  const suppliers: Supplier[] = [];
  for (const name of supplierNames) {
    let s = await supplierRepo.findOne({ where: { name } });
    if (!s) s = await supplierRepo.save(supplierRepo.create({ name, feedType: "manual", contactInfo: "demo@supplier.pk" }));
    suppliers.push(s);
  }
  console.log(`✔ ${suppliers.length} suppliers ready`);

  // ---------- Products + Variants + Supplier links ----------
  const products: Product[] = [];
  for (let i = 0; i < PRODUCT_TEMPLATES.length; i++) {
    const t = PRODUCT_TEMPLATES[i];
    let product = await productRepo.findOne({ where: { name: t.name } });
    if (!product) {
      product = productRepo.create({
        name: t.name,
        description: `${t.name} — demo seed product for ${t.category}.`,
        category: categories[t.category],
        fulfillmentType: FulfillmentType.DROPSHIP,
        basePrice: t.price,
        images: [`https://picsum.photos/seed/seed${i}/400/400`],
        status: ProductStatus.ACTIVE,
      });
      product = await productRepo.save(product);

      const sizes = ["S", "M", "L", "XL"];
      const variants = sizes.map((size, vi) =>
        variantRepo.create({
          product,
          sku: `SEED-${i}-${size}`,
          size,
          price: t.price + vi * 100,
          stockQty: 20 + vi * 5,
        }),
      );
      await variantRepo.save(variants);

      const supplier = suppliers[i % suppliers.length];
      await supplierProductRepo.save(
        supplierProductRepo.create({ supplier, product, costPrice: t.price * 0.7, syncStatus: "synced" }),
      );
    }
    products.push(product);
  }
  console.log(`✔ ${products.length} products with variants + supplier links ready`);

  // ---------- Customers + Addresses ----------
  const customers: User[] = [];
  for (let i = 0; i < CUSTOMER_NAMES.length; i++) {
    const phone = `+92300000${(1000 + i).toString().slice(-4)}`;
    let user = await userRepo.findOne({ where: { phone } });
    if (!user) {
      user = await userRepo.save(userRepo.create({ name: CUSTOMER_NAMES[i], phone, role: UserRole.CUSTOMER }));
      await addressRepo.save(
        addressRepo.create({
          user,
          label: "Home",
          addressLine: `House ${i + 1}, Street ${i + 2}, DHA Phase ${(i % 6) + 1}`,
          city: ["Lahore", "Karachi", "Islamabad", "Faisalabad"][i % 4],
          isDefault: true,
        }),
      );
    }
    customers.push(user);
  }
  console.log(`✔ ${customers.length} customers with addresses ready`);

  // ---------- Sales (Orders) across the last 30 days ----------
  const statuses = [OrderStatus.DELIVERED, OrderStatus.SHIPPED, OrderStatus.CONFIRMED, OrderStatus.PLACED, OrderStatus.CANCELLED];
  const paymentMethods = ["COD", "JAZZCASH", "EASYPAISA", "CARD"];
  let ordersCreated = 0;

  for (let day = 0; day < 30; day++) {
    const ordersToday = Math.floor(Math.random() * 4) + 1; // 1-4 orders/day
    for (let o = 0; o < ordersToday; o++) {
      const customer = customers[Math.floor(Math.random() * customers.length)];
      const address = await addressRepo.findOne({ where: { user: { id: customer.id } } });
      if (!address) continue;

      const itemCount = Math.floor(Math.random() * 3) + 1;
      const chosenProducts = Array.from({ length: itemCount }, () => products[Math.floor(Math.random() * products.length)]);

      const createdAt = new Date();
      createdAt.setDate(createdAt.getDate() - day);

      const status = statuses[Math.floor(Math.random() * statuses.length)];
      const paymentMethod = paymentMethods[Math.floor(Math.random() * paymentMethods.length)];

      let total = 0;
      const orderItemsData: { variant: ProductVariant; qty: number; price: number }[] = [];
      for (const p of chosenProducts) {
        const variants = await variantRepo.find({ where: { product: { id: p.id } } });
        if (!variants.length) continue;
        const variant = variants[Math.floor(Math.random() * variants.length)];
        const qty = Math.floor(Math.random() * 2) + 1;
        total += Number(variant.price) * qty;
        orderItemsData.push({ variant, qty, price: variant.price });
      }
      if (!orderItemsData.length) continue;

      const order = await orderRepo.save(
        orderRepo.create({ user: customer, address, status, paymentMethod, total }),
      );
      // @CreateDateColumn is populated by TypeORM on insert regardless of what
      // was passed to create(), so backdating for the sales-history spread
      // requires an explicit update pass after the row exists.
      await orderRepo
        .createQueryBuilder()
        .update(Order)
        .set({ createdAt })
        .where("id = :id", { id: order.id })
        .execute();
      order.createdAt = createdAt;

      const orderItems = orderItemsData.map((d) =>
        orderItemRepo.create({
          order,
          variant: d.variant,
          qty: d.qty,
          price: d.price,
          fulfillmentTypeSnapshot: FulfillmentType.DROPSHIP,
        }),
      );
      await orderItemRepo.save(orderItems);

      await paymentRepo.save(
        paymentRepo.create({
          order,
          provider: paymentMethod,
          status: status === OrderStatus.CANCELLED ? PaymentStatus.FAILED : PaymentStatus.SUCCESS,
          transactionRef: `SEED-${order.id.slice(0, 8)}`,
        }),
      );

      ordersCreated++;
    }
  }
  console.log(`✔ ${ordersCreated} sample orders (sales) seeded across the last 30 days`);

  await ds.destroy();
  console.log("Seeding complete.");
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
