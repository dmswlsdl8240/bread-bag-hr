// Vercel 빌드 시 환경변수로 config.js를 생성합니다.
// 로컬 개발에서는 사용되지 않습니다 (config.example.js를 config.js로 복사해서 쓰세요).
const fs = require('fs');

const required = ['SUPABASE_URL', 'SUPABASE_KEY'];
const missing = required.filter((key) => !process.env[key]);
if (missing.length) {
  console.error(`Missing required env vars: ${missing.join(', ')}`);
  process.exit(1);
}

const esc = (s) => String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'");

const content = `window.HR_CONFIG = {
  supabaseUrl: '${esc(process.env.SUPABASE_URL)}',
  supabaseKey: '${esc(process.env.SUPABASE_KEY)}',
  designerEmail: '${esc(process.env.DESIGNER_EMAIL || '')}',
  emailjsService: '${esc(process.env.EMAILJS_SERVICE || '')}',
  emailjsTemplate: '${esc(process.env.EMAILJS_TEMPLATE || '')}',
  emailjsPublicKey: '${esc(process.env.EMAILJS_PUBLIC_KEY || '')}',
};
`;

fs.writeFileSync('config.js', content);
console.log('config.js generated from environment variables.');
