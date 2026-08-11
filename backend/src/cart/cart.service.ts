import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Cart } from "../entities/cart.entity";
import { CartItem } from "../entities/cart-item.entity";
import { ProductVariant } from "../entities/product-variant.entity";
import { AddCartItemDto } from "./dto/add-item.dto";

@Injectable()
export class CartService {
  constructor(
    @InjectRepository(Cart) private cartRepo: Repository<Cart>,
    @InjectRepository(CartItem) private itemRepo: Repository<CartItem>,
    @InjectRepository(ProductVariant) private variantRepo: Repository<ProductVariant>,
  ) {}

  async getOrCreateActiveCart(userId: string) {
    let cart = await this.cartRepo.findOne({
      where: { user: { id: userId }, status: "active" },
      relations: ["items", "items.variant", "items.variant.product"],
    });
    if (!cart) {
      cart = this.cartRepo.create({ user: { id: userId } as any, status: "active", items: [] });
      cart = await this.cartRepo.save(cart);
    }
    return cart;
  }

  async addItem(userId: string, dto: AddCartItemDto) {
    const cart = await this.getOrCreateActiveCart(userId);
    const variant = await this.variantRepo.findOne({ where: { id: dto.variantId } });
    if (!variant) throw new NotFoundException("Variant not found");

    const existing = cart.items?.find((i) => i.variant?.id === dto.variantId);
    if (existing) {
      existing.qty += dto.qty;
      await this.itemRepo.save(existing);
    } else {
      const item = this.itemRepo.create({ cart, variant, qty: dto.qty });
      await this.itemRepo.save(item);
    }
    return this.getOrCreateActiveCart(userId);
  }

  async updateItemQty(userId: string, itemId: string, qty: number) {
    const item = await this.itemRepo.findOne({ where: { id: itemId }, relations: ["cart", "cart.user"] });
    if (!item || item.cart.user?.id !== userId) throw new NotFoundException("Cart item not found");
    item.qty = qty;
    return this.itemRepo.save(item);
  }

  async removeItem(userId: string, itemId: string) {
    const item = await this.itemRepo.findOne({ where: { id: itemId }, relations: ["cart", "cart.user"] });
    if (!item || item.cart.user?.id !== userId) throw new NotFoundException("Cart item not found");
    await this.itemRepo.remove(item);
    return this.getOrCreateActiveCart(userId);
  }

  async clear(userId: string) {
    const cart = await this.getOrCreateActiveCart(userId);
    if (cart.items?.length) await this.itemRepo.remove(cart.items);
    return this.getOrCreateActiveCart(userId);
  }
}
