import { Injectable, NotFoundException } from "@nestjs/common";
import { InMemoryCustomersStore } from "./users.store";
import { CreateCustomerDto } from "./dto/create-customer.dto";

@Injectable()
export class UsersService {
  constructor(private readonly store: InMemoryCustomersStore) {}

  findAll() {
    return this.store.findAll();
  }

  findOne(id: string) {
    const customer = this.store.findOne(id);
    if (!customer) throw new NotFoundException("Customer not found");
    return customer;
  }

  create(dto: CreateCustomerDto) {
    return this.store.create({
      name: dto.name,
      email: dto.email,
      phone: dto.phone,
      city: dto.city,
      avatarUrl: dto.avatarUrl ?? `https://api.dicebear.com/7.x/notionists/svg?seed=${encodeURIComponent(dto.name)}`,
      joinedAt: new Date().toISOString(),
      status: dto.status ?? "active",
    });
  }
}
