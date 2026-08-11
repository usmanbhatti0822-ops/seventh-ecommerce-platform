import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";
import { ProductsService } from "./products.service";
import { CreateProductDto } from "./dto/create-product.dto";
import { UpdateProductDto } from "./dto/update-product.dto";
import { Roles, RolesGuard } from "../auth/roles.guard";

@Controller("products")
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll(@Query("categoryId") categoryId?: string, @Query("search") search?: string) {
    return this.productsService.findAll({ categoryId, search });
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.productsService.findOne(id);
  }

  @Post()
  @UseGuards(AuthGuard("jwt"), RolesGuard)
  @Roles("OWNER", "MANAGER", "CATALOG_EDITOR")
  create(@Body() dto: CreateProductDto) {
    return this.productsService.create(dto);
  }

  @Post("import")
  @UseGuards(AuthGuard("jwt"), RolesGuard)
  @Roles("OWNER", "MANAGER", "CATALOG_EDITOR")
  bulkImport(@Body() rows: CreateProductDto[]) {
    return this.productsService.bulkImport(rows);
  }

  @Patch(":id")
  @UseGuards(AuthGuard("jwt"), RolesGuard)
  @Roles("OWNER", "MANAGER", "CATALOG_EDITOR")
  update(@Param("id") id: string, @Body() dto: UpdateProductDto) {
    return this.productsService.update(id, dto);
  }

  @Delete(":id")
  @UseGuards(AuthGuard("jwt"), RolesGuard)
  @Roles("OWNER", "MANAGER")
  remove(@Param("id") id: string) {
    return this.productsService.remove(id);
  }
}
