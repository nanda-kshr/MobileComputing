import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { ObjectId } from 'mongodb';

process.env.MONGODB_DB = 'capstone_test_orders';

import { getDatabase, closeDatabase } from '../lib/mongodb';
import { GET as getOrders, POST as postOrder } from '../app/api/orders/route';
import { GET as getOrderById } from '../app/api/orders/[id]/route';

test('Orders & Inventory Deduction Suite', async (t) => {
  const db = await getDatabase();
  await db.collection('orders').deleteMany({});
  await db.collection('products').deleteMany({});

  after(async () => {
    await closeDatabase();
  });

  // Seed sample products for order testing
  const p1 = await db.collection('products').insertOne({
    name: 'Espresso Beans 500g',
    price: 15.0,
    category: 'Beverages',
    stockQuantity: 10,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
  const p1Id = p1.insertedId.toString();

  const p2 = await db.collection('products').insertOne({
    name: 'Chocolate Muffin',
    price: 3.5,
    category: 'Bakery',
    stockQuantity: 5,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
  const p2Id = p2.insertedId.toString();

  await t.test('POST /api/orders - Validation errors', async () => {
    // Empty body
    const res1 = await postOrder(new Request('http://localhost:3000/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }));
    assert.equal(res1.status, 400);

    // Empty items array
    const res2 = await postOrder(new Request('http://localhost:3000/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items: [] }),
    }));
    assert.equal(res2.status, 400);

    // Invalid quantity
    const res3 = await postOrder(new Request('http://localhost:3000/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items: [{ productId: p1Id, quantity: 0 }] }),
    }));
    assert.equal(res3.status, 400);

    // Non-existent product
    const fakeId = new ObjectId().toString();
    const res4 = await postOrder(new Request('http://localhost:3000/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items: [{ productId: fakeId, quantity: 1 }] }),
    }));
    assert.equal(res4.status, 404);
  });

  await t.test('POST /api/orders - Insufficient stock check', async () => {
    // p2 has 5 in stock; request 6
    const res = await postOrder(new Request('http://localhost:3000/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: [{ productId: p2Id, quantity: 6 }],
      }),
    }));
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Insufficient stock/i);

    // Verify stock did NOT change
    const checkProduct = await db.collection('products').findOne({ _id: new ObjectId(p2Id) });
    assert.equal(checkProduct?.stockQuantity, 5);
  });

  let createdOrderId: string = '';

  await t.test('POST /api/orders - Happy path & Automatic Inventory Deduction', async () => {
    // Buy 2 of p1 (price 15.00 * 2 = 30.00) and 1 of p2 (price 3.50 * 1 = 3.50)
    // Subtotal: 33.50
    // Tax (5%): 1.68
    // Total: 35.18
    const res = await postOrder(new Request('http://localhost:3000/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: [
          { productId: p1Id, quantity: 2 },
          { productId: p2Id, quantity: 1 },
        ],
        paymentMethod: 'card',
      }),
    }));
    assert.equal(res.status, 201);
    const order = await res.json();
    assert.ok(order._id);
    createdOrderId = order._id.toString();

    assert.equal(order.subtotal, 33.5);
    assert.equal(order.tax, 1.68);
    assert.equal(order.total, 35.18);
    assert.equal(order.paymentMethod, 'card');
    assert.equal(order.status, 'completed');
    assert.equal(order.items.length, 2);

    // CRITICAL: Verify stock deduction in MongoDB!
    const product1After = await db.collection('products').findOne({ _id: new ObjectId(p1Id) });
    const product2After = await db.collection('products').findOne({ _id: new ObjectId(p2Id) });

    // p1 started at 10, sold 2 -> should be 8
    assert.equal(product1After?.stockQuantity, 8);
    // p2 started at 5, sold 1 -> should be 4
    assert.equal(product2After?.stockQuantity, 4);
  });

  await t.test('GET /api/orders - List orders', async () => {
    const res = await getOrders();
    assert.equal(res.status, 200);
    const orders = await res.json();
    assert.ok(Array.isArray(orders));
    assert.ok(orders.length >= 1);
    assert.equal(orders[0]._id.toString(), createdOrderId);
  });

  await t.test('GET /api/orders/[id] - Retrieve single order', async () => {
    // 404 unknown
    const fakeId = new ObjectId().toString();
    const res404 = await getOrderById(new Request(`http://localhost:3000/api/orders/${fakeId}`), {
      params: Promise.resolve({ id: fakeId }),
    });
    assert.equal(res404.status, 404);

    // 200 found
    const res200 = await getOrderById(new Request(`http://localhost:3000/api/orders/${createdOrderId}`), {
      params: Promise.resolve({ id: createdOrderId }),
    });
    assert.equal(res200.status, 200);
    const order = await res200.json();
    assert.equal(order._id.toString(), createdOrderId);
    assert.equal(order.total, 35.18);
  });
});
