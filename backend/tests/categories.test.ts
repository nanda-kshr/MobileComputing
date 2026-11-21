import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { ObjectId } from 'mongodb';

process.env.MONGODB_DB = 'capstone_test_categories';

import { getDatabase, closeDatabase } from '../lib/mongodb';
import { GET as getCategories, POST as postCategory } from '../app/api/categories/route';
import { GET as getCategoryById, PUT as putCategoryById, DELETE as deleteCategoryById } from '../app/api/categories/[id]/route';

test('Categories API Suite', async (t) => {
  const db = await getDatabase();
  await db.collection('categories').deleteMany({});

  after(async () => {
    await closeDatabase();
  });

  await t.test('POST /api/categories - Validation errors', async () => {
    // Missing body
    const res1 = await postCategory(new Request('http://localhost:3000/api/categories', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }));
    assert.equal(res1.status, 400);
    const body1 = await res1.json();
    assert.match(body1.error, /Category name is required/i);

    // Empty name
    const res2 = await postCategory(new Request('http://localhost:3000/api/categories', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: '   ' }),
    }));
    assert.equal(res2.status, 400);
  });

  let createdId: string = '';

  await t.test('POST /api/categories - Happy path', async () => {
    const res = await postCategory(new Request('http://localhost:3000/api/categories', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Stationery', description: 'Office supplies' }),
    }));
    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.name, 'Stationery');
    assert.equal(body.description, 'Office supplies');
    assert.ok(body._id);
    createdId = body._id.toString();

    // Side effect check: verify in DB
    const found = await db.collection('categories').findOne({ name: 'Stationery' });
    assert.ok(found);
  });

  await t.test('POST /api/categories - Duplicate category check', async () => {
    const res = await postCategory(new Request('http://localhost:3000/api/categories', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'stationery' }),
    }));
    assert.equal(res.status, 409);
  });

  await t.test('GET /api/categories - List categories', async () => {
    const res = await getCategories();
    assert.equal(res.status, 200);
    const list = await res.json();
    assert.ok(Array.isArray(list));
    assert.ok(list.length >= 1);
  });

  await t.test('GET /api/categories/[id] - Not found and Happy path', async () => {
    // 400 invalid ID
    const resBad = await getCategoryById(new Request(`http://localhost:3000/api/categories/123`), {
      params: Promise.resolve({ id: 'invalid-id' }),
    });
    assert.equal(resBad.status, 400);

    // 404 unknown ID
    const res404 = await getCategoryById(new Request(`http://localhost:3000/api/categories/507f1f77bcf86cd799439011`), {
      params: Promise.resolve({ id: '507f1f77bcf86cd799439011' }),
    });
    assert.equal(res404.status, 404);

    // Happy path
    const resGood = await getCategoryById(new Request(`http://localhost:3000/api/categories/${createdId}`), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(resGood.status, 200);
    const body = await resGood.json();
    assert.equal(body.name, 'Stationery');
  });

  await t.test('PUT /api/categories/[id] - Update category', async () => {
    const res = await putCategoryById(new Request(`http://localhost:3000/api/categories/${createdId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ description: 'Updated Office supplies' }),
    }), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.description, 'Updated Office supplies');
  });

  await t.test('DELETE /api/categories/[id] - Delete category and side effect', async () => {
    const res = await deleteCategoryById(new Request(`http://localhost:3000/api/categories/${createdId}`, {
      method: 'DELETE',
    }), {
      params: Promise.resolve({ id: createdId }),
    });
    assert.equal(res.status, 200);

    // Confirm deleted in DB
    const found = await db.collection('categories').findOne({ _id: new ObjectId(createdId) });
    assert.equal(found, null);
  });
});
