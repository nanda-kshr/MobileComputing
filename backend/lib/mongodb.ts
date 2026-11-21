import { MongoClient, Db } from 'mongodb';

const uri = process.env.MONGODB_URI;
if (!uri) {
  throw new Error('Please define MONGODB_URI in .env');
}

const dbName = process.env.MONGODB_DB || 'capstone';

let clientPromise: Promise<MongoClient>;

declare global {
  // eslint-disable-next-line no-var
  var _mongoClientPromise: Promise<MongoClient> | undefined;
}

if (process.env.NODE_ENV === 'development') {
  if (!global._mongoClientPromise) {
    const client = new MongoClient(uri);
    global._mongoClientPromise = client.connect();
  }
  clientPromise = global._mongoClientPromise;
} else {
  const client = new MongoClient(uri);
  clientPromise = client.connect();
}

export async function getDatabase(customDbName?: string): Promise<Db> {
  const connectedClient = await clientPromise;
  return connectedClient.db(customDbName || dbName);
}

export async function closeDatabase(): Promise<void> {
  const connectedClient = await clientPromise;
  await connectedClient.close();
}

export default clientPromise;
