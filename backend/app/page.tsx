'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';

export default function Home() {
  const [stats, setStats] = useState({
    productsCount: 0,
    categoriesCount: 0,
    ordersCount: 0,
    status: 'Connecting...',
  });

  useEffect(() => {
    async function fetchStats() {
      try {
        const [productsRes, categoriesRes, ordersRes] = await Promise.all([
          fetch('/api/products').then((r) => r.json()).catch(() => []),
          fetch('/api/categories').then((r) => r.json()).catch(() => []),
          fetch('/api/orders').then((r) => r.json()).catch(() => []),
        ]);

        setStats({
          productsCount: Array.isArray(productsRes) ? productsRes.length : 0,
          categoriesCount: Array.isArray(categoriesRes) ? categoriesRes.length : 0,
          ordersCount: Array.isArray(ordersRes) ? ordersRes.length : 0,
          status: 'Connected',
        });
      } catch (err) {
        setStats((prev) => ({
          ...prev,
          status: err instanceof Error ? err.message : 'Error',
        }));
      }
    }

    fetchStats();
  }, []);

  const endpoints = [
    { method: 'GET / POST', path: '/api/products', desc: 'Manage products, search & filter by category' },
    { method: 'GET / PUT / DELETE', path: '/api/products/[id]', desc: 'Manage single product by ObjectId' },
    { method: 'GET / POST', path: '/api/categories', desc: 'List and create product categories' },
    { method: 'GET / PUT / DELETE', path: '/api/categories/[id]', desc: 'Manage category by ObjectId' },
    { method: 'GET / POST', path: '/api/orders', desc: 'Order history & checkout sale with stock deduction' },
    { method: 'GET', path: '/api/orders/[id]', desc: 'Retrieve order receipt and details by ID' },
    { method: 'GET / POST', path: '/api/seed', desc: 'Seed database with sample catalog items (?force=true)' },
  ];

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 p-6 md:p-12 font-sans">
      <header className="max-w-4xl mx-auto mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight">CapStore POS & Inventory System</h1>
            <p className="text-slate-600 mt-1">Next.js REST API & MongoDB Atlas Backend</p>
          </div>
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-100 text-emerald-800 text-sm font-medium">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
            MongoDB: {stats.status}
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto space-y-8">
        {/* Statistics Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="text-sm font-medium text-slate-500">Total Products</div>
            <div className="text-3xl font-bold mt-1 text-slate-900">{stats.productsCount}</div>
          </div>
          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="text-sm font-medium text-slate-500">Categories</div>
            <div className="text-3xl font-bold mt-1 text-slate-900">{stats.categoriesCount}</div>
          </div>
          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="text-sm font-medium text-slate-500">Processed Orders</div>
            <div className="text-3xl font-bold mt-1 text-slate-900">{stats.ordersCount}</div>
          </div>
        </div>

        {/* REST API Routes Reference */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
            <h2 className="text-lg font-semibold text-slate-900">Standard REST API Endpoints</h2>
            <span className="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 rounded-md">Next.js 16</span>
          </div>
          <ul className="divide-y divide-slate-100">
            {endpoints.map((ep, idx) => (
              <li key={idx} className="p-4 hover:bg-slate-50 transition flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-mono font-semibold px-2 py-0.5 rounded bg-slate-100 text-slate-800">
                      {ep.method}
                    </span>
                    <Link href={ep.path.includes('[') ? '#' : ep.path} className="font-mono text-sm font-medium text-blue-600 hover:underline">
                      {ep.path}
                    </Link>
                  </div>
                  <p className="text-xs text-slate-500 mt-1">{ep.desc}</p>
                </div>
                {!ep.path.includes('[') && (
                  <Link
                    href={ep.path}
                    target="_blank"
                    className="self-start sm:self-auto text-xs px-3 py-1 rounded bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium"
                  >
                    View JSON →
                  </Link>
                )}
              </li>
            ))}
          </ul>
        </div>

        {/* Mobile Flutter App Connection Guide */}
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-900 mb-2">Mobile Staff App (Flutter)</h2>
          <p className="text-sm text-slate-600 mb-3">
            The Flutter app in <code className="bg-slate-100 px-1 py-0.5 rounded font-mono text-xs">/app</code> connects to this backend to provide:
          </p>
          <ul className="text-sm text-slate-700 space-y-1.5 list-disc pl-5">
            <li><strong>Product Catalog:</strong> Real-time search, category filters, and live stock availability badges.</li>
            <li><strong>Cart & Mobile Billing:</strong> Live item subtotals, configurable taxes (5%), total bill calculation, payment method selection (Cash, Card, UPI), and instant receipt generation.</li>
            <li><strong>Inventory Management:</strong> Automatic stock deduction in MongoDB Atlas when sales are processed, preventing overselling.</li>
          </ul>
        </div>
      </main>
    </div>
  );
}
