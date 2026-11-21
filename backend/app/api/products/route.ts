import { getDatabase } from '@/lib/mongodb';
import { ObjectId } from 'mongodb';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('q') || searchParams.get('search');
    const category = searchParams.get('category');

    const db = await getDatabase();
    const query: Record<string, unknown> = {};

    if (search && search.trim() !== '') {
      query.$or = [
        { name: { $regex: search.trim(), $options: 'i' } },
        { description: { $regex: search.trim(), $options: 'i' } },
      ];
    }

    if (category && category !== 'All') {
      query.category = { $regex: new RegExp(`^${category.trim()}$`, 'i') };
    }

    const products = await db.collection('products').find(query).sort({ createdAt: -1 }).toArray();
    return Response.json(products);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json().catch(() => null);
    if (!body || typeof body !== 'object') {
      return Response.json({ error: 'Request body must be a valid JSON object' }, { status: 400 });
    }

    const { name, price, stockQuantity, category, description, sku } = body;

    if (!name || typeof name !== 'string' || name.trim() === '') {
      return Response.json({ error: 'Product name is required' }, { status: 400 });
    }

    if (price === undefined || typeof price !== 'number' || price < 0 || isNaN(price)) {
      return Response.json({ error: 'Product price must be a non-negative number' }, { status: 400 });
    }

    if (
      stockQuantity === undefined ||
      typeof stockQuantity !== 'number' ||
      stockQuantity < 0 ||
      !Number.isInteger(stockQuantity)
    ) {
      return Response.json({ error: 'Product stockQuantity must be a non-negative integer' }, { status: 400 });
    }

    if (!category || typeof category !== 'string' || category.trim() === '') {
      return Response.json({ error: 'Product category is required' }, { status: 400 });
    }

    const db = await getDatabase();
    const newProduct = {
      name: name.trim(),
      description: typeof description === 'string' ? description.trim() : '',
      price: Math.round(price * 100) / 100,
      category: category.trim(),
      stockQuantity,
      sku: typeof sku === 'string' ? sku.trim() : '',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const result = await db.collection('products').insertOne(newProduct);
    return Response.json({ _id: result.insertedId, ...newProduct }, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}
