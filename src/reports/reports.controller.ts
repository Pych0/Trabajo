import { Controller, Get, Res } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { Response } from 'express';
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, OneToMany } from 'typeorm';
import { User } from '../users/user.entity';
import { OrderItem } from '../orders/order-item.entity';


@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('pdf')
  async getPdfReport(@Res() res: Response) {
    const buffer = await this.reportsService.generatePdfReport();
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename=report.pdf',
      'Content-Length': buffer.length,
    });
    res.end(buffer);
  }

  @Get('csv')
  async getCsvReport(@Res() res: Response) {
    const buffer = await this.reportsService.generateCsvReport();
    res.set({
      'Content-Type': 'text/csv',
      'Content-Disposition': 'attachment; filename=report.csv',
      'Content-Length': buffer.length,
    });
    res.end(buffer);
  }
}
