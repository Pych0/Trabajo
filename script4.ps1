# Define variables
$baseDir = "src"
$authDir = "$baseDir/auth"
$usersDir = "$baseDir/users"
$dtoDir = "$authDir/dto"

# Crear DTO LoginDto
Write-Host "Creando DTO LoginDto..."
@"
export class LoginDto {
  email: string;
  password: string;
}
"@ | Out-File "$dtoDir/login.dto.ts" -Force

# Actualizar servicio AuthService
Write-Host "Actualizando servicio AuthService..."
@"
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async login(loginDto: LoginDto): Promise<{ access_token: string }> {
    const { email, password } = loginDto;
    const user = await this.usersService.findOne(email);
    if (!user || user.password !== password) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const payload = { username: user.email, sub: user.id };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }

  async validateToken(token: string): Promise<any> {
    try {
      return this.jwtService.verify(token);
    } catch (e) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}
"@ | Out-File "$authDir/auth.service.ts" -Force

# Actualizar servicio UsersService
Write-Host "Actualizando servicio UsersService..."
@"
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user = this.usersRepository.create(createUserDto);
    return this.usersRepository.save(user);
  }

  async findOne(email: string): Promise<User | undefined> {
    return this.usersRepository.findOne({ where: { email } });
  }
}
"@ | Out-File "$usersDir/users.service.ts" -Force

Write-Host "Script completado. Los métodos 'login', 'validateToken' y 'create' han sido añadidos."