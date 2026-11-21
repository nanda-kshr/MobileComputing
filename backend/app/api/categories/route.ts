import { getDatabase } from '@/lib/mongodb';
import { ObjectId } from 'mongodb';

export async function GET() {
  try {
    const db = await getDatabase();
    const categories = await db.collection('categories').find().sort({ name: 1 }).toArray();
    return Response.json(categories);
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

    const { name, description } = body;
    if (!name || typeof name !== 'string' || name.trim() === '') {
      return Response.json({ error: 'Category name is required' }, { status: 400 });
    }

    const db = await getDatabase();
    const trimmedName = name.trim();

    const existing = await db.collection('categories').findOne({
      name: { $regex: new RegExp(`^${trimmedName}$`, 'i') },
    });
    if (existing) {
      return Response.json({ error: `Category "${trimmedName}" already exists` }, { status: 409 });
    }

    const newCategory = {
      name: trimmedName,
      description: typeof description === 'string' ? description.trim() : '',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const result = await db.collection('categories').insertOne(newCategory);
    return Response.json({ _id: result.insertedId, ...newCategory }, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}
