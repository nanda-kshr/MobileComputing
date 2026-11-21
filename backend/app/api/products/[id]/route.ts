import { getDatabase } from '@/lib/mongodb';
import { ObjectId } from 'mongodb';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (!ObjectId.isValid(id)) {
      return Response.json({ error: 'Invalid product ID' }, { status: 400 });
    }

    const db = await getDatabase();
    const product = await db.collection('products').findOne({ _id: new ObjectId(id) });
    if (!product) {
      return Response.json({ error: 'Product not found' }, { status: 404 });
    }

    return Response.json(product);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (!ObjectId.isValid(id)) {
      return Response.json({ error: 'Invalid product ID' }, { status: 400 });
    }

    const body = await request.json().catch(() => null);
    if (!body || typeof body !== 'object') {
      return Response.json({ error: 'Request body must be a valid JSON object' }, { status: 400 });
    }

    const updateFields: Record<string, unknown> = { updatedAt: new Date() };

    if (body.name !== undefined) {
      if (typeof body.name !== 'string' || body.name.trim() === '') {
        return Response.json({ error: 'Product name cannot be empty' }, { status: 400 });
      }
      updateFields.name = body.name.trim();
    }

    if (body.price !== undefined) {
      if (typeof body.price !== 'number' || body.price < 0 || isNaN(body.price)) {
        return Response.json({ error: 'Product price must be a non-negative number' }, { status: 400 });
      }
      updateFields.price = Math.round(body.price * 100) / 100;
    }

    if (body.stockQuantity !== undefined) {
      if (typeof body.stockQuantity !== 'number' || body.stockQuantity < 0 || !Number.isInteger(body.stockQuantity)) {
        return Response.json({ error: 'Product stockQuantity must be a non-negative integer' }, { status: 400 });
      }
      updateFields.stockQuantity = body.stockQuantity;
    }

    if (body.category !== undefined) {
      if (typeof body.category !== 'string' || body.category.trim() === '') {
        return Response.json({ error: 'Product category cannot be empty' }, { status: 400 });
      }
      updateFields.category = body.category.trim();
    }

    if (body.description !== undefined) {
      updateFields.description = typeof body.description === 'string' ? body.description.trim() : '';
    }

    if (body.sku !== undefined) {
      updateFields.sku = typeof body.sku === 'string' ? body.sku.trim() : '';
    }

    const db = await getDatabase();
    const result = await db.collection('products').findOneAndUpdate(
      { _id: new ObjectId(id) },
      { $set: updateFields },
      { returnDocument: 'after' }
    );

    if (!result) {
      return Response.json({ error: 'Product not found' }, { status: 404 });
    }

    return Response.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (!ObjectId.isValid(id)) {
      return Response.json({ error: 'Invalid product ID' }, { status: 400 });
    }

    const db = await getDatabase();
    const result = await db.collection('products').deleteOne({ _id: new ObjectId(id) });
    if (result.deletedCount === 0) {
      return Response.json({ error: 'Product not found' }, { status: 404 });
    }

    return Response.json({ message: 'Product deleted successfully', _id: id });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}
