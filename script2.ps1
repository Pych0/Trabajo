# Define variables
$baseDir = "src"
$ordersDir = "$baseDir/orders"
$dtoDir = "$ordersDir/dto"

# Crear directorios necesarios
Write-Host "Creando directorios necesarios..."
New-Item -ItemType Directory -Path $ordersDir -Force
New-Item -ItemType Directory -Path $dtoDir -Force

# Crear entidad Order
Write-Host "Creando entidad Order..."
@"
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, OneToMany } from 'typeorm';
import { User } from '../users/user.entity';
import { Product } from '../products/product.entity';

@Entity()
export class Order {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => User, user => user.orders)
  user: User;

  @OneToMany(() => OrderItem, orderItem => orderItem.order, { cascade: true })
  items: OrderItem[];

  @Column()
  total: number;
}
"@ | Out-File "$ordersDir/order.entity.ts" -Force

# Crear entidad OrderItem
Write-Host "Creando entidad OrderItem..."
@"
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne } from 'typeorm';
import { Order } from './order.entity';
import { Product } from '../products/product.entity';

@Entity()
export class OrderItem {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Order, order => order.items)
  order: Order;

  @ManyToOne(() => Product)
  product: Product;

  @Column()
  quantity: number;

  @Column()
  price: number;
}
"@ | Out-File "$ordersDir/order-item.entity.ts" -Force

# Crear DTO CreateOrderDto
Write-Host "Creando DTO CreateOrderDto..."
@"
export class CreateOrderDto {
  userId: number;
  items: { productId: number, quantity: number }[];
}
"@ | Out-File "$dtoDir/create-order.dto.ts" -Force

# Crear servicio OrdersService
Write-Host "Creando servicio OrdersService..."
@"
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
    // Implementar lógica de actualización si es necesario
    return this.ordersRepository.save(order);
  }

  async remove(id: number): Promise<void> {
    const result = await this.ordersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Order not found');
    }
  }
}
"@ | Out-File "$ordersDir/orders.service.ts" -Force

# Crear controlador OrdersController
Write-Host "Creando controlador OrdersController..."
@"
import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@Body() createOrderDto: CreateOrderDto) {
    return this.ordersService.create(createOrderDto);
  }

  @Get()
  findAll() {
    return this.ordersService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: number) {
    return this.ordersService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: number, @Body() updateOrderDto: CreateOrderDto) {
    return this.ordersService.update(id, updateOrderDto);
  }

  @Delete(':id')
  remove(@Param('id') id: number) {
    return this.ordersService.remove(id);
  }
}
"@ | Out-File "$ordersDir/orders.controller.ts" -Force

# Crear módulo OrdersModule
Write-Host "Creando módulo OrdersModule..."
@"
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { Order } from './order.entity';
import { OrderItem } from './order-item.entity';
import { User } from '../users/user.entity';
import { Product } from '../products/product.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Order, OrderItem, User, Product])],
  providers: [OrdersService],
  controllers: [OrdersController],
})
export class OrdersModule {}
"@ | Out-File "$ordersDir/orders.module.ts" -Force

# Actualizar AppModule para incluir OrdersModule
Write-Host "Actualizando AppModule para incluir OrdersModule..."
@"
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { CategoriesModule } from './categories/categories.module';
import { ProductsModule } from './products/products.module';
import { OrdersModule } from './orders/orders.module';
import { AuthMiddleware } from './auth/auth.middleware';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: '',
      database: 'ba.datos',
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: true,
    }),
    UsersModule,
    AuthModule,
    CategoriesModule,
    ProductsModule,
    OrdersModule,
  ],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .forRoutes('protected-route');
  }
}
"@ | Out-File "$baseDir/app.module.ts" -Force

Write-Host "Script completado. Las funcionalidades de pedidos han sido añadidas a tu proyecto NestJS."