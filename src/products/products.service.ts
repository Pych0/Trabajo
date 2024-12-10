import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './product.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { Category } from '../categories/category.entity';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private productsRepository: Repository<Product>,
    @InjectRepository(Category)
    private categoriesRepository: Repository<Category>,
  ) {}

  async create(createProductDto: CreateProductDto): Promise<Product> {
    const category = await this.categoriesRepository.findOneBy({ id: createProductDto.categoryId });
    if (!category) {
      throw new NotFoundException('Category not found');
    }
    const product = this.productsRepository.create({ ...createProductDto, category });
    return this.productsRepository.save(product);
  }

  async findAll(): Promise<Product[]> {
    return this.productsRepository.find({ relations: ['category'] });
  }

  async findOne(id: number): Promise<Product> {
    const product = await this.productsRepository.findOneBy({ id });
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return product;
  }

  async update(id: number, updateProductDto: CreateProductDto): Promise<Product> {
    const category = await this.categoriesRepository.findOneBy({ id: updateProductDto.categoryId });
    if (!category) {
      throw new NotFoundException('Category not found');
    }
    await this.productsRepository.update(id, { ...updateProductDto, category });
    const updatedProduct = await this.productsRepository.findOneBy({ id });
    if (!updatedProduct) {
      throw new NotFoundException('Product not found');
    }
    return updatedProduct;
  }

  async remove(id: number): Promise<void> {
    const result = await this.productsRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Product not found');
    }
  }

  async findByCategory(categoryId: number): Promise<Product[]> {
    return this.productsRepository.find({
      where: { category: { id: categoryId } },
      relations: ['category'],
    });
  }
}