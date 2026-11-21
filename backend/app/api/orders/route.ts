import { getDatabase } from '@/lib/mongodb';
import { ObjectId } from 'mongodb';

export async function GET() {
  try {
    const db = await getDatabase();
    const orders = await db.collection('orders').find().sort({ createdAt: -1 }).toArray();
    return Response.json(orders);
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

    const { items, paymentMethod = 'cash', staffId } = body;

    if (!Array.isArray(items) || items.length === 0) {
      return Response.json({ error: 'Order must contain at least one item' }, { status: 400 });
    }

    // Validate item shapes
    for (const item of items) {
      if (
        !item ||
        typeof item !== 'object' ||
        !item.productId ||
        typeof item.productId !== 'string' ||
        !ObjectId.isValid(item.productId)
      ) {
        return Response.json({ error: 'Each order item must specify a valid productId string' }, { status: 400 });
      }

      if (
        item.quantity === undefined ||
        typeof item.quantity !== 'number' ||
        item.quantity <= 0 ||
        !Number.isInteger(item.quantity)
      ) {
        return Response.json({ error: 'Each order item quantity must be an integer greater than zero' }, { status: 400 });
      }
    }

    const db = await getDatabase();

    // Group quantities if same product appears multiple times in cart
    const itemMap = new Map<string, number>();
    for (const item of items) {
      const current = itemMap.get(item.productId) || 0;
      itemMap.set(item.productId, current + item.quantity);
    }

    const productObjectIds = Array.from(itemMap.keys()).map((id) => new ObjectId(id));
    const products = await db
      .collection('products')
      .find({ _id: { $in: productObjectIds } })
      .toArray();

    const productMap = new Map(products.map((p) => [p._id.toString(), p]));

    // Check that every product exists and has sufficient stock
    const validatedOrderItems: {
      productId: string;
      productName: string;
      quantity: number;
      price: number;
      subtotal: number;
    }[] = [];
    let subtotal = 0;

    for (const [productId, quantity] of itemMap.entries()) {
      const product = productMap.get(productId);
      if (!product) {
        return Response.json({ error: `Product not found: ${productId}` }, { status: 404 });
      }

      if (product.stockQuantity < quantity) {
        return Response.json(
          {
            error: `Insufficient stock for "${product.name}". Available: ${product.stockQuantity}, Requested: ${quantity}`,
            productId,
            availableStock: product.stockQuantity,
          },
          { status: 400 }
        );
      }

      const itemSubtotal = Math.round(product.price * quantity * 100) / 100;
      subtotal += itemSubtotal;
      validatedOrderItems.push({
        productId,
        productName: product.name,
        quantity,
        price: product.price,
        subtotal: itemSubtotal,
      });
    }

    // Atomic stock deduction for each product
    const deductedRecords: { id: ObjectId; quantity: number }[] = [];

    for (const [productId, quantity] of itemMap.entries()) {
      const objId = new ObjectId(productId);
      const updateResult = await db.collection('products').updateOne(
        { _id: objId, stockQuantity: { $gte: quantity } },
        {
          $inc: { stockQuantity: -quantity },
          $set: { updatedAt: new Date() },
        }
      );

      if (updateResult.modifiedCount === 0) {
        // Rollback already deducted items if concurrency conflict occurred
        for (const record of deductedRecords) {
          await db.collection('products').updateOne(
            { _id: record.id },
            { $inc: { stockQuantity: record.quantity } }
          );
        }

        return Response.json(
          {
            error: 'Stock conflict detected during transaction. Please refresh and try again.',
            productId,
          },
          { status: 409 }
        );
      }

      deductedRecords.push({ id: objId, quantity });
    }

    subtotal = Math.round(subtotal * 100) / 100;
    const tax = Math.round(subtotal * 0.05 * 100) / 100; // 5% tax
    const total = Math.round((subtotal + tax) * 100) / 100;

    const newOrder = {
      items: validatedOrderItems,
      subtotal,
      tax,
      total,
      paymentMethod: typeof paymentMethod === 'string' ? paymentMethod : 'cash',
      status: 'completed',
      staffId: typeof staffId === 'string' ? staffId : 'staff_1',
      createdAt: new Date(),
    };

    const orderResult = await db.collection('orders').insertOne(newOrder);

    return Response.json(
      {
        _id: orderResult.insertedId,
        ...newOrder,
      },
      { status: 201 }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}
