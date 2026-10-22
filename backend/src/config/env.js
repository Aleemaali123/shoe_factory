import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT || 4000),
  jwtSecret: process.env.JWT_SECRET || 'shoe-factory-dev-secret',
  databasePath: process.env.DATABASE_PATH || 'data/shop.db',
};
