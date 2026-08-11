import { daysAgo } from "./id.util";
import { MockStaffMember, StaffRole } from "./types";
import { UserRole } from "../../entities/user.entity";

/** Internal staff/admin accounts, shown on the admin panel's "Staff" (RBAC) screen — see PRD section 4.2. */
interface StaffSeedRow {
  name: string;
  role: StaffRole;
  joinedDaysAgo: number;
  active: boolean;
}

const RAW: StaffSeedRow[] = [
  { name: "Ahmed Raza", role: UserRole.OWNER, joinedDaysAgo: 700, active: true },
  { name: "Nida Farooqi", role: UserRole.MANAGER, joinedDaysAgo: 520, active: true },
  { name: "Junaid Malik", role: UserRole.CATALOG_EDITOR, joinedDaysAgo: 300, active: true },
  { name: "Sarah Bukhari", role: UserRole.SUPPORT, joinedDaysAgo: 180, active: true },
  { name: "Kamran Iqbal", role: UserRole.SUPPORT, joinedDaysAgo: 90, active: false },
];

export const STAFF: MockStaffMember[] = RAW.map((s, i) => ({
  id: `staff_${String(i + 1).padStart(3, "0")}`,
  name: s.name,
  email: `${s.name.toLowerCase().replace(/\s+/g, ".")}@seventh.pk`,
  role: s.role,
  joinedAt: daysAgo(s.joinedDaysAgo),
  active: s.active,
}));
