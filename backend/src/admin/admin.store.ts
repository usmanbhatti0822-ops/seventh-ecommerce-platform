import { Injectable } from "@nestjs/common";
import { STAFF, MockStaffMember, generateMockId } from "../common/mock-data";

/**
 * DEMO MODE: staff/admin accounts live in memory — there is no `staff`
 * table in `entities/` (only the 12 core commerce entities exist; RBAC
 * roles themselves are real, defined on `UserRole` in `entities/user.entity.ts`
 * and enforced by `RolesGuard`, this store just supplies the directory data
 * for the admin panel's "Staff" screen — PRD 4.2).
 */
@Injectable()
export class InMemoryStaffStore {
  private staff: MockStaffMember[] = STAFF.map((s) => ({ ...s }));

  findAll(): MockStaffMember[] {
    return [...this.staff];
  }

  findOne(id: string): MockStaffMember | undefined {
    return this.staff.find((s) => s.id === id);
  }

  create(data: Omit<MockStaffMember, "id" | "joinedAt">): MockStaffMember {
    const member: MockStaffMember = { ...data, id: generateMockId("staff"), joinedAt: new Date().toISOString() };
    this.staff.push(member);
    return member;
  }
}
