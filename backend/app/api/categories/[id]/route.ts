import { getDatabase } from '@/lib/mongodb';
import { ObjectId } from 'mongodb';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (!ObjectId.isValid(id)) {
      return Response.json({ error: 'Invalid category ID' }, { status: 400 });
    }

    const db = await getDatabase();
    const category = await db.collection('categories').findOne({ _id: new ObjectId(id) });
    if (!category) {
      return Response.json({ error: 'Category not found' }, { status: 404 });
    }

    return Response.json(category);
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
      return Response.json({ error: 'Invalid category ID' }, { status: 400 });
    }

    const body = await request.json().catch(() => null);
    if (!body || typeof body !== 'object') {
      return Response.json({ error: 'Request body must be a valid JSON object' }, { status: 400 });
    }

    const updateFields: Record<string, unknown> = { updatedAt: new Date() };

    if (body.name !== undefined) {
      if (typeof body.name !== 'string' || body.name.trim() === '') {
        return Response.json({ error: 'Category name cannot be empty' }, { status: 400 });
      }
      updateFields.name = body.name.trim();
    }

    if (body.description !== undefined) {
      updateFields.description = typeof body.description === 'string' ? body.description.trim() : '';
    }

    const db = await getDatabase();
    const result = await db.collection('categories').findOneAndUpdate(
      { _id: new ObjectId(id) },
      { $set: updateFields },
      { returnDocument: 'after' }
    );

    if (!result) {
      return Response.json({ error: 'Category not found' }, { status: 404 });
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
      return Response.json({ error: 'Invalid category ID' }, { status: 400 });
    }

    const db = await getDatabase();
    const result = await db.collection('categories').deleteOne({ _id: new ObjectId(id) });
    if (result.deletedCount === 0) {
      return Response.json({ error: 'Category not found' }, { status: 404 });
    }

    return Response.json({ message: 'Category deleted successfully', _id: id });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}
