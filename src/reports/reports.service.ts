import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../orders/order.entity';
import * as PDFDocument from 'pdfkit';
import * as createCsvWriter from 'csv-writer';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Order)
    private ordersRepository: Repository<Order>,
  ) {}

  async generatePdfReport(): Promise<Buffer> {
    const orders = await this.ordersRepository.find({ relations: ['user', 'orderItems', 'orderItems.product'] });

    const doc = new PDFDocument();
    const buffers: Buffer[] = [];
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => buffers);

    doc.fontSize(25).text('Reporte de Pedidos', { align: 'center' });

    orders.forEach(order => {
      doc
        .fontSize(18)
        .text(`Pedido ID: ${order.id}`)
        .fontSize(12)
        .text(`Usuario: ${order.user.name}`)
        .text(`Total: ${order.totalPrice}`)
        .text(`Estado: ${order.status}`)
        .moveDown();
    });

    doc.end();
    return Buffer.concat(buffers);
  }

  async generateCsvReport(): Promise<Buffer> {
    const orders = await this.ordersRepository.find({ relations: ['user', 'orderItems', 'orderItems.product'] });

    const csvWriter = createCsvWriter.createObjectCsvWriter({
      path: 'orders-report.csv',
      header: [
        { id: 'id', title: 'ID' },
        { id: 'user', title: 'Usuario' },
        { id: 'totalPrice', title: 'Total' },
        { id: 'status', title: 'Estado' },
      ],
    });

    const records = orders.map(order => ({
      id: order.id,
      user: order.user.name,
      totalPrice: order.totalPrice,
      status: order.status,
    }));

    await csvWriter.writeRecords(records);

    return Buffer.from(csvWriter.toString());
  }
}
