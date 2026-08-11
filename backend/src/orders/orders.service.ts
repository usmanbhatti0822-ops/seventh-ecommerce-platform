import { Injectable, NotFoundException, BadRequestException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Order, OrderStatus } from "../entities/order.entity";
import { OrderItem } from "../entities/order-item.entity";
import { Address } from "../entities/address.entity";
import { CartService } from "../cart/cart.service";
import { FulfillmentService } from "./fulfillment.service";
import { CreateOrderDto } from "./dto/create-order.dto";

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order) private orderRepo: Repository<Order>,
    @InjectRepository(OrderItem) private orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Address) private addressRepo: Repository<Address>,
    private cartService: CartService,
    private fulfillmentService: FulfillmentService,
  ) {}

  async findAllForUser(userId: string) {
    return this.orderRepo.find({
      where: { user: { id: userId } },
      relations: ["items", "items.variant", "address"],
      order: { createdAt: "DESC" },
    });
  }

  async findOne(id: string) {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: ["items", "items.variant", "items.variant.product", "address", "user"],
    });
    if (!order) throw new NotFoundException("Order not found");
    return order;
  }

  /** Places an order from the user's active cart, then clears the cart. */
  async createFromCart(userId: string, dto: CreateOrderDto) {
    const cart = await this.cartService.getOrCreateActiveCart(userId);
    if (!cart.items?.length) throw new BadRequestException("Cart is empty");

    const address = await this.addressRepo.findOne({ where: { id: dto.addressId } });
    if (!address) throw new NotFoundException("Address not found");

    const total = cart.items.reduce((sum, item) => sum + Number(item.variant.price) * item.qty, 0);

    const order = this.orderRepo.create({
      user: { id: userId } as any,
      address,
      paymentMethod: dto.paymentMethod,
      status: OrderStatus.PLACED,
      total,
    });
    const savedOrder = await this.orderRepo.save(order);

    const orderItems = cart.items.map((item) =>
      this.orderItemRepo.create({
        order: savedOrder,
        variant: item.variant,
        qty: item.qty,
        price: item.variant.price,
        fulfillmentTypeSnapshot: item.variant.product?.fulfillmentType,
      }),
    );
    await this.orderItemRepo.save(orderItems);

    // Route each item to supplier (dropship) or warehouse (own-stock)
    for (const item of orderItems) {
      await this.fulfillmentService.routeOrderItem(item.fulfillmentTypeSnapshot, item.id);
    }

    await this.cartService.clear(userId);
    return this.findOne(savedOrder.id);
  }

  async updateStatus(id: string, status: OrderStatus) {
    const order = await this.findOne(id);
    this.assertValidTransition(order.status, status);
    order.status = status;
    return this.orderRepo.save(order);
  }

  async cancel(id: string, userId: string) {
    const order = await this.findOne(id);
    if (order.user.id !== userId) throw new BadRequestException("Not your order");
    if (order.status !== OrderStatus.PLACED && order.status !== OrderStatus.CONFIRMED) {
      throw new BadRequestException("Order can no longer be cancelled");
    }
    order.status = OrderStatus.CANCELLED;
    return this.orderRepo.save(order);
  }

  private assertValidTransition(from: OrderStatus, to: OrderStatus) {
    const allowed: Record<OrderStatus, OrderStatus[]> = {
      [OrderStatus.PLACED]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
      [OrderStatus.CONFIRMED]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
      [OrderStatus.SHIPPED]: [OrderStatus.OUT_FOR_DELIVERY],
      [OrderStatus.OUT_FOR_DELIVERY]: [OrderStatus.DELIVERED],
      [OrderStatus.DELIVERED]: [OrderStatus.RETURN_REQUESTED],
      [OrderStatus.RETURN_REQUESTED]: [OrderStatus.REFUNDED],
      [OrderStatus.CANCELLED]: [],
      [OrderStatus.REFUNDED]: [],
    };
    if (!allowed[from]?.includes(to)) {
      throw new BadRequestException(`Cannot transition order from ${from} to ${to}`);
    }
  }
}
