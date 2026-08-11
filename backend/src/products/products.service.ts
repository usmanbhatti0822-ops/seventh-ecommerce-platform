import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Product, ProductStatus } from "../entities/product.entity";
import { ProductVariant } from "../entities/product-variant.entity";
import { Category } from "../entities/category.entity";
import { CreateProductDto } from "./dto/create-product.dto";
import { UpdateProductDto } from "./dto/update-product.dto";

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product) private productsRepo: Repository<Product>,
    @InjectRepository(ProductVariant) private variantsRepo: Repository<ProductVariant>,
    @InjectRepository(Category) private categoriesRepo: Repository<Category>,
  ) {}

  async findAll(filters?: { categoryId?: string; search?: string }) {
    const qb = this.productsRepo
      .createQueryBuilder("product")
      .leftJoinAndSelect("product.variants", "variant")
      .leftJoinAndSelect("product.category", "category")
      .where("product.status = :status", { status: ProductStatus.ACTIVE });

    if (filters?.categoryId) {
      qb.andWhere("category.id = :categoryId", { categoryId: filters.categoryId });
    }
    if (filters?.search) {
      qb.andWhere("product.name ILIKE :search", { search: `%${filters.search}%` });
    }
    return qb.getMany();
  }

  async findOne(id: string) {
    const product = await this.productsRepo.findOne({
      where: { id },
      relations: ["variants", "category"],
    });
    if (!product) throw new NotFoundException("Product not found");
    return product;
  }

  async create(dto: CreateProductDto) {
    const product = this.productsRepo.create({
      name: dto.name,
      description: dto.description,
      basePrice: dto.basePrice,
      images: dto.images || [],
      fulfillmentType: dto.fulfillmentType,
      status: ProductStatus.DRAFT,
    });

    if (dto.categoryId) {
      const category = await this.categoriesRepo.findOne({ where: { id: dto.categoryId } });
      if (category) product.category = category;
    }

    const saved = await this.productsRepo.save(product);

    if (dto.variants?.length) {
      const variants = dto.variants.map((v) =>
        this.variantsRepo.create({ ...v, product: saved }),
      );
      await this.variantsRepo.save(variants);
    }

    return this.findOne(saved.id);
  }

  async update(id: string, dto: UpdateProductDto) {
    const product = await this.findOne(id);
    Object.assign(product, dto);
    return this.productsRepo.save(product);
  }

  async bulkImport(rows: CreateProductDto[]) {
    // TODO: stream large CSVs instead of loading all rows in memory
    const results = [];
    for (const row of rows) {
      results.push(await this.create(row));
    }
    return { imported: results.length };
  }

  async remove(id: string) {
    const product = await this.findOne(id);
    product.status = ProductStatus.ARCHIVED;
    return this.productsRepo.save(product);
  }
}
