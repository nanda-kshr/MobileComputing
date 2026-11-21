import { ObjectId } from 'mongodb';

export interface Category {
  _id?: ObjectId | string;
  name: string;
  description?: string;
  createdAt: Date;
  updatedAt?: Date;
}

export interface Product {
  _id?: ObjectId | string;
  name: string;
  description?: string;
  price: number;
  category: string;
  stockQuantity: number;
  sku?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface OrderItem {
  productId: string;
  productName: string;
  quantity: number;
  price: number;
  subtotal: number;
}

export interface Order {
  _id?: ObjectId | string;
  items: OrderItem[];
  subtotal: number;
  tax: number;
  total: number;
  paymentMethod: 'cash' | 'card' | 'upi' | string;
  status: 'completed' | 'cancelled';
  createdAt: Date;
}
