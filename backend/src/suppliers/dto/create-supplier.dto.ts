export class CreateSupplierDto {
  name: string;
  contactInfo?: string;
  feedType?: "manual" | "csv" | "api";
}
