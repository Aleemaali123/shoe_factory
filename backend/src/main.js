import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { env } from './config/env.js';
import { openStore } from './infrastructure/persistence/jsonStore.js';
import { createTokens } from './infrastructure/security/tokens.js';
import { createApp } from './interfaces/http/createApp.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const store = await openStore(path.resolve(root, env.storePath));
const app = createApp({ store, tokens: createTokens(env.jwtSecret) });

app.listen(env.port, () => {
  console.log(`Shoe Factory API listening on http://127.0.0.1:${env.port}`);
});
