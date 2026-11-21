import test, { after } from 'node:test';
import assert from 'node:assert/strict';

process.env.MONGODB_DB = 'capstone_test_products';

import { getDatabase, closeDatabase } from '../lib/mongodb';
import { GET as getProducts, POST as postProduct } from '../app/api/products/route';
import { GET as getProductById, PUT as putProductById, DELETE as deleteProductById } from '../app/api/products/[id]/route';

test('Products API Suite', async (t) => {
  const db = await getDatabase();
  await db.collection('products').deleteMany({});

  after(async () => {
    await closeDatabase();
  });

  await t.test('POST /api/products - Validation errors', async () => {
    // Missing required fields
    const res1 = await postProduct(new Request('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }));
    assert.equal(res1.status, 400);

    // Negative price
    const res2 = await postProduct(new Request('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Milk', price: -5, stockQuantity: 10, category: 'Dairy' }),
    }));
    assert.equal(res2.status, 400);

    // Negative stock
    const res3 = await postProduct(new Request('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Milk', price: 3.5, stockQuantity: -1, category: 'Dairy' }),
    }));
    assert.equal(res3.status, 400);

    // Non-integer stock
    const res4 = await postProduct(new Request('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Milk', price: 3.5, stockQuantity: 2.5, category: 'Dairy' }),
    }));
    assert.equal(res4.status, 400);
  });

  let createdId: string = '';

  await t.test('POST /api/products - Happy path & side effect', async () => {
    const res = await postProduct(new Request('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Whole Milk 1L',
        description: 'Fresh pasteurized whole milk',
        price: 3.49,
        category: 'Dairy',
        stockQuantity: 50,
        sku: 'DAI-101',
      }),
    }));
    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.name, 'Whole Milk 1L');
    assert.equal(body.price, 3.49);
    assert.equal(body.stockQuantity, 50);
    assert.equal(body.category, 'Dairy');
    assert.ok(body._id);
    createdId = body._id.toString();

    // Verify side effect in DB
    const found = await db.collection('products').findOne({ sku: 'DAI-101' });
    assert.ok(found);
    assert.equal(found.stockQuantity, 50);
  });

  await t.test('GET /api/products - List, search, category filter', async () => {
    // Insert another product
    await postProduct(new Request('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Sourdough Bread',
        description: 'Artisan baked bread loaf',
        price: 4.99,
        category: 'Bakery',
        stockQuantity: 20,
        sku: 'BAK-101',
      }),
    }));

    // List all
    const resAll = await getProducts(new Request('http://localhost:3000/api/products'));
    assert.equal(resAll.status, 200);
    const all = await resAll.json();
    assert.equal(all.length, 2);

    // Search by query
    const resSearch = await getProducts(new Request('http://localhost:3000/api/products?q=sourdough'));
    assert.equal(resSearch.status, 200);
    const searchResults = await resSearch.json();
    assert.equal(searchResults.length, 1);
    assert.equal(searchResults[0].name, 'Sourdough Bread');

    // Filter by category
    const resCat = await getProducts(new Request('http://localhost:3000/api/products?category=Dairy'));
    assert.equal(resCat.status, 200);
    const catResults = await resCat.json();
    assert.equal(catResults.length, 1);
    assert.equal(catResults[0].category, 'Dairy');
  });

  await t.test('GET /api/products/[id] - Not found and Happy path', async () => {
    // Invalid ID format
    const resBad = await getProductById(new Request(`http://localhost:3000/api/products/bad-id`), {
      params: Promise.resolve({ id: 'bad-id' }),
    });
    assert.equal(resBad.status, 400);

    // Not found
    const res404 = await getProductById(new Request(`http://localhost:3000/api/products/507f1f77bcf86cd799439011`), {
      params: Promise.resolve({ id: '507f1f77bcf86cd799439011' }),
    });
    assert.equal(res404.status, 404);

    // Happy path
    const resGood = await getProductById(new Request(`http://localhost:3000/api/products/${createdId}`), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(resGood.status, 200);
    const body = await resGood.json();
    assert.equal(body.name, 'Whole Milk 1L');
  });

  await t.test('PUT /api/products/[id] - Update product & validations', async () => {
    // Bad price update
    const resBad = await putProductById(new Request(`http://localhost:3000/api/products/${createdId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ price: -10 }),
    }), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(resBad.status, 400);

    // Valid price and stock update
    const resGood = await putProductById(new Request(`http://localhost:3000/api/products/${createdId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ price: 3.99, stockQuantity: 65 }),
    }), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(resGood.status, 200);
    const body = await resGood.json();
    assert.equal(body.price, 3.99);
    assert.equal(body.stockQuantity, 65);
  });

  await t.test('DELETE /api/products/[id] - Delete and verify side effect', async () => {
    const res = await deleteProductById(new Request(`http://localhost:3000/api/products/${createdId}`, {
      method: 'DELETE',
    }), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(res.status, 200);

    const check = await getProductById(new Request(`http://localhost:3000/api/products/${createdId}`), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(check.status, 404);
  });
});
