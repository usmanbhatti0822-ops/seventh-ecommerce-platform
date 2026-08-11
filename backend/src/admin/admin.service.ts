import { Injectable, NotFoundException } from "@nestjs/common";
import { InMemoryStaffStore } from "./admin.store";
import { CreateStaffDto } from "./dto/create-staff.dto";
import { UsersService } from "../users/users.service";
import { TOP_PRODUCTS, RECENT_ORDERS, DashboardSummary } from "../common/mock-data";

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

@Injectable()
export class AdminService {
  constructor(
    private readonly staffStore: InMemoryStaffStore,
    private readonly usersService: UsersService,
  ) {}

  findAll() {
    return this.staffStore.findAll();
  }

  findOne(id: string) {
    const member = this.staffStore.findOne(id);
    if (!member) throw new NotFoundException("Staff member not found");
    return member;
  }

  create(dto: CreateStaffDto) {
    return this.staffStore.create({
      name: dto.name,
      email: dto.email,
      role: dto.role,
      active: dto.active ?? true,
    });
  }

  /**
   * Aggregate stats for the admin dashboard (PRD 4.2: "sales, orders, revenue,
   * top products, customer growth"). Figures are derived from the seeded
   * customer directory rather than a live order-book query — this is demo
   * data, so it's shaped to look plausible rather than computed from real rows.
   */
  getDashboard(): DashboardSummary {
    const customers = this.usersService.findAll();
    const lifetimeRevenue = customers.reduce((sum, c) => sum + c.totalSpentPkr, 0);
    const lifetimeOrders = customers.reduce((sum, c) => sum + c.orderCount, 0);
    const newLast30Days = customers.filter(
      (c) => Date.now() - new Date(c.joinedAt).getTime() <= THIRTY_DAYS_MS,
    ).length;

    return {
      revenue: {
        last30DaysPkr: Math.round(lifetimeRevenue * 0.22),
        last7DaysPkr: Math.round(lifetimeRevenue * 0.06),
        changePct: 12.4,
      },
      orders: {
        last30Days: Math.round(lifetimeOrders * 0.3) + 18,
        last7Days: Math.round(lifetimeOrders * 0.08) + 4,
        changePct: 8.1,
      },
      customers: {
        total: customers.length,
        newLast30Days,
      },
      topProducts: TOP_PRODUCTS,
      recentOrders: RECENT_ORDERS,
    };
  }
}
