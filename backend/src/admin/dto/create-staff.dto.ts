import { StaffRole } from "../../common/mock-data";

export class CreateStaffDto {
  name: string;
  email: string;
  role: StaffRole;
  active?: boolean;
}
