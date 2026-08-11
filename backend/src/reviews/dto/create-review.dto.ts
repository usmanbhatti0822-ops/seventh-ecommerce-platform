export class CreateReviewDto {
  productId: string;
  productName: string;
  rating: number; // 1-5
  comment: string;
  reviewerName: string;
  verifiedPurchase?: boolean;
}
