# AGENT.md - Project Overview & Guidelines

## Stack & Test Setup

### Backend (`/backend`)
- **Framework:** Next.js 16.4.6 (App Router), React 19.3.0, TypeScript
- **Database:** MongoDB Atlas via native `mongodb` Node.js driver (v7+)
- **Environment:** Configured in `backend/.env` with `MONGODB_URI`
- **Test Framework:** Node.js native test runner (`node:test`, `node:assert`)
- **Test Command:** `cd backend && npm test`

### Mobile App (`/app`)
- **Framework:** Flutter (SDK ^3.10.8), Dart 3.10.8
- **Dependencies:** `http`, `cupertino_icons`, `flutter_lints`
- **Test Framework:** `flutter_test`
- **Test Command:** `cd app && flutter test`

---

## Architecture & REST Endpoints

### Backend REST API Routes
- `GET /api/products` - List products with optional `?search=` and `?category=` query filters
- `POST /api/products` - Create product (`name`, `price`, `stockQuantity`, `category`, optional `description`, `sku`)
- `GET /api/products/[id]` - Get single product by ObjectId
- `PUT /api/products/[id]` - Update product details or stock
- `DELETE /api/products/[id]` - Delete product
- `GET /api/categories` - List all categories
- `POST /api/categories` - Create new category
- `GET /api/categories/[id]` - Get category by ObjectId
- `PUT /api/categories/[id]` - Update category
- `DELETE /api/categories/[id]` - Delete category
- `GET /api/orders` - List completed sales orders (history)
- `POST /api/orders` - Process sales transaction & billing:
  - Validates cart items and verifies sufficient stock in MongoDB
  - Atomically deducts inventory (`$inc: { stockQuantity: -qty }`)
  - Computes bill totals: subtotal, tax (5%), and grand total
  - Records order in `orders` collection
- `GET /api/orders/[id]` - Retrieve order details by ObjectId
- `POST /api/seed` - Initialize sample products and categories if DB is empty

### Mobile App Structure (`/app/lib`)
- `models/`: `Product`, `Category`, `CartItem`, `OrderModel`
- `services/api_service.dart`: HTTP REST client communicating with Next.js backend
- `screens/catalog_screen.dart`: Product catalog displaying products, category filtering, search, and stock indicators
- `screens/cart_screen.dart`: Mobile billing flow with quantity controls, live total calculation, payment selection, and checkout transaction processing
- `main.dart`: App entry point with theme and navigation
