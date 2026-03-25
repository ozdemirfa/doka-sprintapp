// SQL dosyalarını Supabase'e sırayla yükler
// Kullanım: node scripts/run-sql.js

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const BASE = path.join(__dirname, '..');
const SQL_DIR = path.join(BASE, 'src', 'sql');

// src/.env'den postgres URL'ini oku
const envContent = fs.readFileSync(path.join(BASE, 'src', '.env'), 'utf8');
const pgUrlLine = envContent.split('\n').find(l => l.startsWith('SUPABASE_SERVICE_ROLE_KEY='));
const pgUrl = pgUrlLine
  .replace('SUPABASE_SERVICE_ROLE_KEY=', '')
  .trim()
  .replace(/^["']|["']$/g, '');

const SQL_FILES = [
  '001_schema.sql',
  '002_views.sql',
  '003_rls.sql',
  '004_triggers.sql',
  'seed.sql',
];

async function main() {
  const client = new Client({
    connectionString: pgUrl,
    ssl: { rejectUnauthorized: false },
  });

  console.log('Supabase bağlantısı kuruluyor...');
  await client.connect();
  console.log('Bağlantı başarılı!\n');

  for (const file of SQL_FILES) {
    const filePath = path.join(SQL_DIR, file);
    const sql = fs.readFileSync(filePath, 'utf8');
    process.stdout.write(`[ÇALIŞIYOR] ${file} ... `);
    try {
      await client.query(sql);
      console.log('OK');
    } catch (err) {
      console.log('HATA');
      console.error(`  → ${err.message}`);
      await client.end();
      process.exit(1);
    }
  }

  await client.end();
  console.log('\nTüm SQL dosyaları başarıyla uygulandı!');
}

main().catch(err => {
  console.error('Beklenmeyen hata:', err.message);
  process.exit(1);
});
