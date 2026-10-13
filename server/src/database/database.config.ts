export function getDatabaseUrl(env: NodeJS.ProcessEnv): string {
  if (env.DATABASE_URL) {
    return env.DATABASE_URL;
  }

  const user = encodeURIComponent(env.DB_USER ?? 'pos');
  const password = encodeURIComponent(env.DB_PASSWORD ?? '');
  const host = env.DB_HOST ?? 'localhost';
  const port = env.DB_PORT ?? '5432';
  const database = encodeURIComponent(env.DB_NAME ?? 'pos');

  return `postgresql://${user}:${password}@${host}:${port}/${database}`;
}
