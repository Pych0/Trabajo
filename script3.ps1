# Define variables
$baseDir = "src"
$usersDir = "$baseDir/users"
$authDir = "$baseDir/auth"

# Actualizar entidad User
Write-Host "Actualizando entidad User..."
@"
import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { Order } from '../orders/order.entity';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @OneToMany(() => Order, order => order.user)
  orders: Order[];
}
"@ | Out-File "$usersDir/user.entity.ts" -Force

# Actualizar servicio UsersService
Write-Host "Actualizando servicio UsersService..."
@"
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findOne(email: string): Promise<User | undefined> {
    return this.usersRepository.findOne({ where: { email } });
  }
}
"@ | Out-File "$usersDir/users.service.ts" -Force

# Actualizar servicio AuthService
Write-Host "Actualizando servicio AuthService..."
@"
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';

@Injectable()
export class AuthService {
  constructor(private usersService: UsersService) {}

  async signIn(email: string, pass: string): Promise<any> {
    const user = await this.usersService.findOne(email);
    if (user && user.password === pass) {
      const { password, ...result } = user;
      return result;
    }
    throw new UnauthorizedException();
  }
}
"@ | Out-File "$authDir/auth.service.ts" -Force

Write-Host "Script completado. Los errores relacionados con las propiedades 'password' y 'email' han sido corregidos."