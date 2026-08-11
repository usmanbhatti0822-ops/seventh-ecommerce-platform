export class RecordMovementDto {
  type: "in" | "out";
  quantity: number;
  reason: string;
}
