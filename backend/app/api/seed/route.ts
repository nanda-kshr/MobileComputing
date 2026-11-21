import { getDatabase } from '@/lib/mongodb';

const SAMPLE_CATEGORIES = [
  { name: 'Beverages', description: 'Hot and cold drinks, juices, soda' },
  { name: 'Bakery', description: 'Fresh bread, buns, pastries' },
  { name: 'Produce', description: 'Fresh fruits and vegetables' },
  { name: 'Dairy & Eggs', description: 'Milk, cheese, butter, eggs' },
  { name: 'Snacks', description: 'Chips, nuts, biscuits, cookies' },
];

const SAMPLE_PRODUCTS = [
  { name: 'Arabica Coffee Beans 250g', price: 12.99, category: 'Beverages', stockQuantity: 45, sku: 'BEV-001' },
  { name: 'Green Tea Box (25 bags)', price: 4.50, category: 'Beverages', stockQuantity: 60, sku: 'BEV-002' },
  { name: 'Fresh Orange Juice 1L', price: 3.99, category: 'Beverages', stockQuantity: 30, sku: 'BEV-003' },
  { name: 'Sourdough Artisanal Loaf', price: 5.49, category: 'Bakery', stockQuantity: 25, sku: 'BAK-001' },
  { name: 'Butter Croissant (Pack of 4)', price: 6.00, category: 'Bakery', stockQuantity: 40, sku: 'BAK-002' },
  { name: 'Whole Milk 1 Gallon', price: 3.79, category: 'Dairy & Eggs', stockQuantity: 50, sku: 'DAI-001' },
  { name: 'Cheddar Cheese Block 200g', price: 4.25, category: 'Dairy & Eggs', stockQuantity: 35, sku: 'DAI-002' },
  { name: 'Organic Honeycrisp Apples 1kg', price: 4.99, category: 'Produce', stockQuantity: 80, sku: 'PRO-001' },
  { name: 'Ripe Hass Avocados (Bag of 4)', price: 3.89, category: 'Produce', stockQuantity: 40, sku: 'PRO-002' },
  { name: 'Sea Salt Potato Crisps 150g', price: 2.99, category: 'Snacks', stockQuantity: 100, sku: 'SNK-001' },
  { name: 'Roasted Almonds 200g', price: 7.49, category: 'Snacks', stockQuantity: 50, sku: 'SNK-002' },
];

export async function POST(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const forceParam = searchParams.get('force') === 'true';

    const db = await getDatabase();
    const existingProductsCount = await db.collection('products').countDocuments();

    if (existingProductsCount > 0 && !forceParam) {
      return Response.json({
        message: 'Database already has data. Pass ?force=true to re-seed.',
        productsCount: existingProductsCount,
      });
    }

    if (forceParam) {
      await db.collection('products').deleteMany({});
      await db.collection('categories').deleteMany({});
      await db.collection('orders').deleteMany({});
    }

    const now = new Date();

    // Insert categories
    const categoriesToInsert = SAMPLE_CATEGORIES.map((cat) => ({
      ...cat,
      createdAt: now,
      updatedAt: now,
    }));
    await db.collection('categories').insertMany(categoriesToInsert);

    // Insert products
    const productsToInsert = SAMPLE_PRODUCTS.map((prod) => ({
      ...prod,
      description: `${prod.name} in category ${prod.category}`,
      createdAt: now,
      updatedAt: now,
    }));
    const productResult = await db.collection('products').insertMany(productsToInsert);

    return Response.json(
      {
        message: 'Database seeded successfully',
        categoriesCount: categoriesToInsert.length,
        productsCount: productResult.insertedCount,
      },
      { status: 201 }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function GET(request: Request) {
  return POST(request);
}
