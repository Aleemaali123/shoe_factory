import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT || 4000),
  jwtSecret: process.env.JWT_SECRET || 'shoe-factory-dev-secret',
  storePath: process.env.STORE_PATH || 'data/store.json',
};
