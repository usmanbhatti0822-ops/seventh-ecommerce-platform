import { Controller, Get, Post, Param, Body, Query, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { ReviewsService } from "./reviews.service";
import { CreateReviewDto } from "./dto/create-review.dto";

@Controller("reviews")
export class ReviewsController {
  constructor(private readonly service: ReviewsService) {}

  @Get()
  findAll(@Query("productId") productId?: string) {
    return this.service.findAll(productId);
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Post()
  @UseGuards(AuthGuard("jwt"))
  create(@Body() dto: CreateReviewDto) {
    return this.service.create(dto);
  }
}
