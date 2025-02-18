import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from './order.entity';
import { OrderItem } from './order-item.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { User } from '../users/user.entity';
import { Product } from '../products/product.entity';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private ordersRepository: Repository<Order>,
    @InjectRepository(OrderItem)
    private orderItemsRepository: Repository<OrderItem>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Product)
    private productsRepository: Repository<Product>,
  ) {}

  async create(createOrderDto: CreateOrderDto): Promise<Order> {
    const user = await this.usersRepository.findOneBy({ id: createOrderDto.userId });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const items = [];
    let total = 0;

    for (const item of createOrderDto.items) {
      const product = await this.productsRepository.findOneBy({ id: item.productId });
      if (!product) {
        throw new NotFoundException('Product not found');
      }
      if (product.stock < item.quantity) {
        throw new BadRequestException('Insufficient stock for product: ' + product.name);
      }
      product.stock -= item.quantity;
      await this.productsRepository.save(product);

      const orderItem = new OrderItem();
      orderItem.product = product;
      orderItem.quantity = item.quantity;
      orderItem.price = product.price * item.quantity;
      items.push(orderItem);
      total += orderItem.price;
    }

    const order = new Order();
    order.user = user;
    order.items = items;
    order.total = total;

    return this.ordersRepository.save(order);
  }

  async findAll(): Promise<Order[]> {
    return this.ordersRepository.find({ relations: ['user', 'items', 'items.product'] });
  }

  async findOne(id: number): Promise<Order> {
    const order = await this.ordersRepository.findOneBy({ id });
    if (!order) {
      throw new NotFoundException('Order not found');
    }
    return order;
  }

  async update(id: number, updateOrderDto: CreateOrderDto): Promise<Order> {
    const order = await this.findOne(id);
    // Implementar lÃ³gica de actualizaciÃ³n si es necesario
    return this.ordersRepository.save(order);
  }

  async remove(id: number): Promise<void> {
    const result = await this.ordersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Order not found');
    }
  }
}
