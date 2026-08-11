export class CreateCustomerDto {
  name: string;
  email: string;
  phone: string;
  city: string;
  avatarUrl?: string;
  status?: "active" | "blocked";
}
