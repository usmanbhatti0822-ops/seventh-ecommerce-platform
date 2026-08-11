import { Injectable } from "@nestjs/common";
import { CUSTOMERS, MockCustomer, generateMockId } from "../common/mock-data";

/**
 * DEMO MODE: this backs the admin panel's "Customers" screen — a directory
 * view (join date, order count, lifetime spend, active/blocked status) that
 * is intentionally separate from the real `User` entity used for OTP/social
 * login auth (see `entities/user.entity.ts` + `auth/auth.service.ts`).
 * There is no dedicated "customer profile" table in `entities/`, so this is
 * seeded in memory for the demo — swap for a real repository/query over
 * `User` + `Order` aggregates later without touching `UsersService`.
 */
@Injectable()
export class InMemoryCustomersStore {
  private customers: MockCustomer[] = CUSTOMERS.map((c) => ({ ...c }));

  findAll(): MockCustomer[] {
    return [...this.customers].sort((a, b) => (a.joinedAt < b.joinedAt ? 1 : -1));
  }

  findOne(id: string): MockCustomer | undefined {
    return this.customers.find((c) => c.id === id);
  }

  create(data: Omit<MockCustomer, "id" | "orderCount" | "totalSpentPkr">): MockCustomer {
    const customer: MockCustomer = {
      ...data,
      id: generateMockId("cust"),
      orderCount: 0,
      totalSpentPkr: 0,
    };
    this.customers.unshift(customer);
    return customer;
  }
}
