/* وِرد — core */
const W = window.W = { pages: {}, tabs: ['home', 'reciters', 'azkar', 'fasting', 'more'], listeners: {} };
const $ = (s, r = document) => r.querySelector(s), $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const pad = n => String(n).padStart(2, '0');
const dkey = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const TD = () => dkey(new Date());
const AR = n => String(n).replace(/\d/g, d => '٠١٢٣٤٥٦٧٨٩'[d]);
const num = n => (W.cfg?.get('arDigits') ? AR(n) : String(n));
const sleep = ms => new Promise(r => setTimeout(r, ms));
W.on = (e, f) => (W.listeners[e] ||= []).push(f);
W.emit = (e, a) => (W.listeners[e] || []).forEach(f => { try { f(a) } catch (x) { console.error(x) } });

/* ---------- icons (Material paths) ---------- */
const P = {
  sunset: 'M12 7a5 5 0 0 0-5 5h10a5 5 0 0 0-5-5zM2 19h20v2H2zM12 3l2.5 2.5-1.4 1.4L12 5.8 10.9 6.9 9.5 5.5zM3.5 9.5l1.4-1.4 1.8 1.8-1.4 1.4zM17.3 9.9l1.8-1.8 1.4 1.4-1.8 1.8zM2 14h3v2H2zm17 0h3v2h-3z',
  send: 'M2.01 21L23 12 2.01 3 2 10l15 2-15 2z', alarmadd: 'M7.88 3.39L6.6 1.86 2 5.71l1.29 1.53 4.59-3.85zM22 5.72l-4.6-3.86-1.29 1.53 4.6 3.86L22 5.72zM12 4c-4.97 0-9 4.03-9 9s4.02 9 9 9c4.97 0 9-4.03 9-9s-4.03-9-9-9zm0 16c-3.87 0-7-3.13-7-7s3.13-7 7-7 7 3.13 7 7-3.13 7-7 7zm1-11h-2v3H8v2h3v3h2v-3h3v-2h-3V9z',
  sort: 'M3 18h6v-2H3v2zM3 6v2h18V6H3zm0 7h12v-2H3v2z', up: 'M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6-6 6z', down: 'M7.41 8.59L12 13.17l4.59-4.58L18 10l-6 6-6-6z',
  eyeoff: 'M12 7c2.76 0 5 2.24 5 5 0 .65-.13 1.26-.36 1.83l2.92 2.92c1.51-1.26 2.7-2.89 3.43-4.75-1.73-4.39-6-7.5-11-7.5-1.4 0-2.74.25-3.98.7l2.16 2.16C10.74 7.13 11.35 7 12 7zM2 4.27l2.28 2.28.46.46C3.08 8.3 1.78 10.02 1 12c1.73 4.39 6 7.5 11 7.5 1.55 0 3.03-.3 4.38-.84l.42.42L19.73 22 21 20.73 3.27 3 2 4.27zM7.53 9.8l1.55 1.55c-.05.21-.08.43-.08.65 0 1.66 1.34 3 3 3 .22 0 .44-.03.65-.08l1.55 1.55c-.67.33-1.41.53-2.2.53-2.76 0-5-2.24-5-5 0-.79.2-1.53.53-2.2z',
  grid: 'M3 3h8v8H3zm10 0h8v8h-8zM3 13h8v8H3zm10 0h8v8h-8z',
  home: 'M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z', back: 'M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z', fwd: 'M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z',
  chev: 'M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z', chevr: 'M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z', check: 'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z',
  fav: 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z',
  favo: 'M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z',
  copy: 'M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z',
  share: 'M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92 1.61 0 2.92-1.31 2.92-2.92s-1.31-2.92-2.92-2.92z',
  refresh: 'M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z',
  bell: 'M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z',
  clock: 'M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z',
  pin: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
  compass: 'M12 10.9c-.61 0-1.1.49-1.1 1.1s.49 1.1 1.1 1.1c.61 0 1.1-.49 1.1-1.1s-.49-1.1-1.1-1.1zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm2.19 12.19L6 18l3.81-8.19L18 6l-3.81 8.19z',
  search: 'M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z',
  close: 'M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z', add: 'M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z',
  del: 'M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z',
  book: 'M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zm0 13.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z',
  flag: 'M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z', star: 'M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z', mark: 'M17 3H7c-1.1 0-1.99.9-1.99 2L5 21l7-3 7 3V5c0-1.1-.9-2-2-2z',
  sun: 'M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zm9-9.95h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-3.21 13.7l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4zM20 10.5v2h3v-2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm-1 16.95h2V19.5h-2v2.95zm-7.45-3.91l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8z',
  moon: 'M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.46-.04-.92-.1-1.36-.98 1.37-2.58 2.26-4.4 2.26-2.98 0-5.4-2.42-5.4-5.4 0-1.81.89-3.42 2.26-4.4-.44-.06-.9-.1-1.36-.1z',
  vol: 'M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z',
  play: 'M8 5v14l11-7z', pause: 'M6 19h4V5H6v14zm8-14v14h4V5h-4z', prev: 'M6 6h2v12H6zm3.5 6l8.5 6V6z', next: 'M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z',
  fire: 'M13.5.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 3.73-2.07 0-3.63-1.67-3.63-3.73l.03-.36C5.21 7.51 4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 17.41 3.8 13.5.67zM11.71 19c-1.78 0-3.22-1.4-3.22-3.14 0-1.62 1.05-2.76 2.81-3.12 1.77-.36 3.6-1.21 4.62-2.58.39 1.29.59 2.65.59 4.04 0 2.65-2.15 4.8-4.8 4.8z',
  user: 'M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z',
  logout: 'M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z',
  sync: 'M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46C19.54 15.03 20 13.57 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74C4.46 8.97 4 10.43 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z',
  cloudoff: 'M19.35 10.04C18.67 6.59 15.64 4 12 4c-1.48 0-2.85.43-4.01 1.17l1.46 1.46C10.21 6.23 11.08 6 12 6c3.04 0 5.5 2.46 5.5 5.5v.5H19c1.66 0 3 1.34 3 3 0 1.13-.64 2.11-1.56 2.62l1.45 1.45C23.16 18.16 24 16.68 24 15c0-2.64-2.05-4.78-4.65-4.96zM3 5.27l2.75 2.74C2.56 8.15 0 10.77 0 14c0 3.31 2.69 6 6 6h11.73l2 2L21 20.73 4.27 4 3 5.27zM7.73 10l8 8H6c-2.21 0-4-1.79-4-4s1.79-4 4-4h1.73z',
  music: 'M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z',
  tune: 'M3 17v2h6v-2H3zM3 5v2h10V5H3zm10 16v-2h8v-2h-8v-2h-2v6h2zM7 9v2H3v2h4v2h2V9H7zm14 4v-2H11v2h10zm-6-4h2V7h4V5h-4V3h-2v6z',
  trophy: 'M19 5h-2V3H7v2H5c-1.1 0-2 .9-2 2v1c0 2.55 1.92 4.63 4.39 4.94.63 1.5 1.98 2.63 3.61 2.96V19H7v2h10v-2h-4v-3.1c1.63-.33 2.98-1.46 3.61-2.96C19.08 12.63 21 10.55 21 8V7c0-1.1-.9-2-2-2zM5 8V7h2v3.82C5.84 10.4 5 9.3 5 8zm14 0c0 1.3-.84 2.4-2 2.82V7h2v1z',
  cal: 'M20 3h-1V1h-2v2H7V1H5v2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 18H4V8h16v13z',
  undo: 'M12.5 8c-2.65 0-5.05.99-6.9 2.6L2 7v9h9l-3.62-3.62c1.39-1.16 3.16-1.88 5.12-1.88 3.54 0 6.55 2.31 7.6 5.5l2.37-.78C21.08 11.03 17.15 8 12.5 8z',
  eye: 'M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z',
  more: 'M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z',
  info: 'M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z',
  spark: 'M19 9l1.25-2.75L23 5l-2.75-1.25L19 1l-1.25 2.75L15 5l2.75 1.25zm-7.5.5L9 4 6.5 9.5 1 12l5.5 2.5L9 20l2.5-5.5L17 12zM19 15l-1.25 2.75L15 19l2.75 1.25L19 23l1.25-2.75L23 19l-2.75-1.25z',
  mosque: 'M12 2c-1 2-2 3-2 4.5S10.9 9 12 9s2-1 2-2.5S13 4 12 2zM4 22V11l2-2 2 2v11zm12 0V11l2-2 2 2v11zM8 22v-7c0-2.2 1.8-4 4-4s4 1.8 4 4v7h-2v-3h-4v3z',
  hand: 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54z',
  water: 'M12 2c-5.33 4.55-8 8.48-8 11.8 0 4.98 3.8 8.2 8 8.2s8-3.22 8-8.2c0-3.32-2.67-7.25-8-11.8z', lock: 'M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zM9 8V6c0-1.66 1.34-3 3-3s3 1.34 3 3v2H9z'
};
const ico = (n, c = '') => `<svg class="i ${c}" viewBox="0 0 24 24" aria-hidden="true"><path d="${P[n] || P.info}"/></svg>`;
const MOSQUE = `<svg class="mos" viewBox="0 0 150 110" fill="currentColor" aria-hidden="true"><rect x="6" y="30" width="16" height="80"/><path d="M6 30l8-24 8 24z"/><rect x="128" y="30" width="16" height="80"/><path d="M128 30l8-24 8 24z"/><path d="M40 70a35 35 0 0 1 70 0z"/><rect x="36" y="70" width="78" height="40"/><path d="M75 18v14M70 24h10" stroke="currentColor" stroke-width="3"/></svg>`;
const GLOGO = `<svg class="i" viewBox="0 0 24 24"><path fill="#4285F4" d="M23.5 12.27c0-.85-.08-1.67-.22-2.45H12v4.64h6.46a5.52 5.52 0 0 1-2.4 3.62v3h3.88c2.27-2.09 3.56-5.17 3.56-8.81z"/><path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.94-2.91l-3.88-3c-1.08.72-2.45 1.15-4.06 1.15-3.13 0-5.78-2.11-6.73-4.96H1.27v3.1A12 12 0 0 0 12 24z"/><path fill="#FBBC05" d="M5.27 14.28A7.2 7.2 0 0 1 4.9 12c0-.79.14-1.56.37-2.28v-3.1H1.27A12 12 0 0 0 0 12c0 1.94.46 3.77 1.27 5.38l4-3.1z"/><path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.43-3.43C17.95 1.19 15.24 0 12 0A12 12 0 0 0 1.27 6.62l4 3.1C6.22 6.86 8.87 4.75 12 4.75z"/></svg>`;
Object.assign(W, { ico, MOSQUE, GLOGO });

/* ---------- store (local-first, per-key timestamps for sync) ---------- */
const LS = 'werd2:';
W.SYNC_KEYS = ['khatma', 'tasbih', 'azkar', 'quran', 'challenges', 'activity', 'settings', 'reminders', 'fast', 'more'];
const store = W.store = {
  meta: (() => { try { return JSON.parse(localStorage.getItem(LS + '__meta')) || {} } catch { return {} } })(),
  get(k, d) { try { const v = localStorage.getItem(LS + k); return v == null ? d : JSON.parse(v) } catch { return d } },
  set(k, v, quiet) { try { localStorage.setItem(LS + k, JSON.stringify(v)) } catch (e) { console.warn(e) } if (W.SYNC_KEYS.includes(k)) { this.meta[k] = Date.now(); localStorage.setItem(LS + '__meta', JSON.stringify(this.meta)) } if (!quiet) W.emit('change', k) },
  /* apply remote value without bumping the local timestamp past remote */
  applyRemote(k, v, ts) { localStorage.setItem(LS + k, JSON.stringify(v)); this.meta[k] = ts; localStorage.setItem(LS + '__meta', JSON.stringify(this.meta)); W.emit('change', k) },
  upd(k, d, fn) { const v = this.get(k, d); const r = fn(v); this.set(k, r === undefined ? v : r); return r === undefined ? v : r },
  clearAll() { Object.keys(localStorage).filter(x => x.startsWith(LS)).forEach(x => localStorage.removeItem(x)); this.meta = {} }
};
/* settings accessor */
W.cfg = {
  def: { mode: 'auto', pal: 'green', zfs: 28, tsound: false, arDigits: false, vibrate: true, hijriAdj: 0 },
  get(k) { const s = store.get('settings', {}); return k in s ? s[k] : this.def[k] },
  set(k, v) { const s = store.get('settings', {}); s[k] = v; store.set('settings', s); applyTheme() }
};
const mq = matchMedia('(prefers-color-scheme: dark)');
function applyTheme() {
  const m = W.cfg.get('mode'), dark = m === 'dark' || (m === 'auto' && mq.matches), r = document.documentElement;
  r.dataset.eff = dark ? 'dark' : 'light'; r.dataset.pal = W.cfg.get('pal') === 'green' ? 'green' : 'burgundy';
  const tc = $('#tc'); if (tc) tc.content = getComputedStyle(r).getPropertyValue('--bg').trim() || '#F6F4EC'; try { WN()?.bars({ dark }) } catch { }
}
mq.addEventListener?.('change', applyTheme); W.applyTheme = applyTheme;

/* ---------- ui helpers ---------- */
let tt; W.toast = m => { const s = $('#sn'); s.textContent = m; s.classList.add('on'); clearTimeout(tt); tt = setTimeout(() => s.classList.remove('on'), 2400) };
/* ---------- haptics أصلية (نبضات tick/click/heavy/success/error) + احتياطي للويب ---------- */
const WN = () => window.Capacitor?.Plugins?.WerdNative;
const HP = { tick: 8, select: 8, click: 14, heavy: 38, success: [16, 50, 30], error: [40, 50, 40, 50, 60] };
W.hap = new Proxy({}, { get: (_, t) => (force) => { if (!force && !W.cfg.get('vibrate')) return; const n = WN(); if (n?.haptic) { n.haptic({ type: t }).catch(() => { }); return } try { navigator.vibrate?.(HP[t] || 12) } catch { } } });
W.vib = ms => { if (Array.isArray(ms)) return W.hap.success(); ms = +ms || 12; ms < 11 ? W.hap.tick() : ms < 24 ? W.hap.click() : ms < 45 ? W.hap.heavy() : W.hap.success() };
/* ---------- ملء الشاشة: مساحات النظام تصل من الأندرويد كمتغيرات CSS ---------- */
W.setInsets = i => { if (!i) return; const r = document.documentElement.style; r.setProperty('--sat', (i.top || 0) + 'px'); r.setProperty('--sab', (i.bottom || 0) + 'px'); r.setProperty('--kb', (i.kb || 0) + 'px'); if (i.kb) setTimeout(() => document.activeElement?.scrollIntoView?.({ block: 'center', behavior: 'smooth' }), 120) };
W.initNative = () => { const n = WN(); if (!n) return; document.documentElement.classList.add('native'); n.insets?.().then(W.setInsets).catch(() => { }); if (!W._nl) { W._nl = 1; n.addListener?.('insets', W.setInsets) } try { n.bars({ dark: document.documentElement.dataset.eff === 'dark' }) } catch { } };
/* صوت نقرة قصير للتسبيح (WebAudio) */
let AC; W.tick = (kind = 'tick') => { try { AC ||= new (window.AudioContext || window.webkitAudioContext)(); if (AC.state === 'suspended') AC.resume(); const t = AC.currentTime, mk = (f, d, v, at = 0) => { const o = AC.createOscillator(), g = AC.createGain(); o.type = 'sine'; o.frequency.value = f; g.gain.setValueAtTime(0, t + at); g.gain.linearRampToValueAtTime(v, t + at + .004); g.gain.exponentialRampToValueAtTime(.0001, t + at + d); o.connect(g).connect(AC.destination); o.start(t + at); o.stop(t + at + d + .02) }; if (kind === 'done') { mk(660, .18, .22); mk(880, .28, .22, .12) } else mk(1250, .06, .18) } catch { } };
document.addEventListener('pointerdown', e => {
  const b = e.target.closest('button,.item,.chip,.pc'); if (!b || b.classList.contains('nr')) return; if (!b.closest('.nh,nav')) W.hap.tick();
  const r = b.getBoundingClientRect(), s = Math.max(r.width, r.height) * 2, d = document.createElement('span'); d.className = 'rip sp';
  d.style.cssText = `width:${s}px;height:${s}px;left:${e.clientX - r.left - s / 2}px;top:${e.clientY - r.top - s / 2}px`;
  if (getComputedStyle(b).position === 'static') b.style.position = 'relative'; b.style.overflow = 'hidden'; b.appendChild(d); setTimeout(() => d.remove(), 600)
}, { passive: true });
let openSh = null;
W.sheet = html => { closeSheet(); const s = $('#sheet'); s.innerHTML = html; openSh = s; requestAnimationFrame(() => { s.classList.add('on'); $('#scrim').classList.add('on') }); return s };
function closeSheet() { $$('.sheet.on').forEach(s => s.classList.remove('on')); $('#scrim').classList.remove('on'); openSh = null; $$('.menu').forEach(m => m.remove()) }
W.closeSheet = closeSheet;
W.dialog = ({ title, body = '', ok = 'حسنًا', cancel = 'إلغاء', danger }) => new Promise(res => {
  const d = $('#dlg'); d.innerHTML = `<div><h3>${esc(title)}</h3><div>${body}</div><div class="acts"><button data-r="1" ${danger ? 'style="color:#A8332B"' : ''}>${ok}</button>${cancel ? `<button data-r="0" style="color:var(--on2)">${cancel}</button>` : ''}</div></div>`;
  d.classList.add('on'); const f = d.querySelector('input'); f && setTimeout(() => f.focus(), 200);
  d.onclick = e => { const b = e.target.closest('[data-r]'); if (!b && e.target !== d) return; const v = b?.dataset.r === '1'; const val = f ? f.value : v; d.classList.remove('on'); res(v ? (f ? { value: val, ok: true } : true) : false) }
});
W.menu = (anchor, items) => {
  closeSheet(); const r = anchor.getBoundingClientRect(), m = document.createElement('div'); m.className = 'menu';
  m.style.top = r.bottom + 6 + 'px'; m.style.insetInlineStart = Math.max(10, r.left) + 'px';
  m.innerHTML = items.map((x, i) => `<button data-i="${i}">${ico(x[0], 'chev')}<span>${x[1]}</span></button>`).join('');
  document.body.appendChild(m); $('#scrim').classList.add('on');
  m.onclick = e => { const b = e.target.closest('button'); if (!b) return; closeSheet(); items[b.dataset.i][2]() }
};
$('#scrim').onclick = closeSheet;
W.share = async (text) => { try { if (navigator.share) await navigator.share({ text }); else { await navigator.clipboard.writeText(text); W.toast('تم النسخ') } } catch { } };
W.copy = async t => { try { await navigator.clipboard.writeText(t); W.toast('تم النسخ') } catch { W.toast('تعذّر النسخ') } };
W.ring = (p, size = 64, w = 7, col = 'var(--pri)', bg = 'var(--surf2)') => { const r = (size - w) / 2, c = 2 * Math.PI * r; return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}"><circle cx="${size / 2}" cy="${size / 2}" r="${r}" stroke="${bg}" stroke-width="${w}"/><circle cx="${size / 2}" cy="${size / 2}" r="${r}" stroke="${col}" stroke-width="${w}" stroke-dasharray="${c}" stroke-dashoffset="${c * (1 - Math.min(1, Math.max(0, p)))}" style="--c:${c}"/></svg>` };
W.top = (title, { back = true, left = '', cls = '' } = {}) => `<div class="top ${cls}">${back ? `<button class="ib" data-back aria-label="رجوع">${ico('chevr')}</button>` : '<span class="sp"></span>'}<h1>${title}</h1>${left || '<span class="sp"></span>'}</div>`;

/* ---------- router: tabs + pushed screens (hash based) ---------- */
let cur = null, depth = 0;
const pageEl = id => { let e = document.getElementById('p-' + id); if (!e) { e = document.createElement('section'); e.id = 'p-' + id; e.className = 'page'; $('#pages').appendChild(e) } return e };
W.go = (r, replace) => { const h = '#/' + r; if (location.hash === h) return route(); replace ? location.replace(h) : (location.hash = h) };
W.back = () => { if (history.length > 1 && depth > 0) history.back(); else W.go('home', true) };
async function route() {
  closeSheet(); let h = location.hash.replace(/^#\/?/, '') || 'home'; const [id, ...args] = h.split('/'), pg = W.pages[id] || W.pages.home, pid = W.pages[id] ? id : 'home';
  const isTab = W.tabs.includes(pid), key = h, prev = cur; if (prev && prev.key === key) return;
  const nd = isTab ? 0 : (prev && !W.tabs.includes(prev.id) ? depth + 1 : 1), pushing = nd > depth && !isTab, popping = nd < depth;
  const el = pageEl(isTab ? pid : key); el.classList.toggle('screen', !isTab);
  if (pg.screen === false) el.classList.remove('screen');
  await pg.render(el, args, pushing); icons(el);
  const pe = prev && document.getElementById('p-' + (W.tabs.includes(prev.id) ? prev.id : prev.key));
  if (pe && pe !== el) { pe.className = pe.className.replace(/\b(on|in-f|in-b|push)\b/g, '').trim(); pe.classList.add(popping ? 'pop' : 'out'); const x = pe; setTimeout(() => { x.classList.remove('out', 'pop'); if (!W.tabs.includes(prev.id)) { x.remove() } }, 300) }
  el.classList.remove('out', 'pop', 'in-f', 'in-b', 'push', 'settled'); void el.offsetWidth; el.classList.add('on'); clearTimeout(el._st); el._st = setTimeout(() => el.classList.add('settled'), 1000);
  if (!isTab && pushing) el.classList.add('push'); else if (isTab && prev && W.tabs.includes(prev.id)) el.classList.add(W.tabs.indexOf(pid) > W.tabs.indexOf(prev.id) ? 'in-f' : 'in-b'); else if (isTab) el.classList.add('in-b');
  depth = nd; cur = { id: pid, key }; $('nav.nav').classList.toggle('hide', !isTab); $$('nav button').forEach(b => b.classList.toggle('on', b.dataset.t === pid));
  W.cur = cur; if (prev) (isTab ? W.hap.select() : pushing ? W.hap.click() : W.hap.tick()); pg.after?.(el, args)
}
function icons(r) { /* hook for future */ }
window.addEventListener('hashchange', route);
document.addEventListener('click', e => { const b = e.target.closest('[data-back]'); if (b) W.back(); const g = e.target.closest('[data-go]'); if (g) W.go(g.dataset.go) });
W.refresh = () => { const el = cur && document.getElementById('p-' + (W.tabs.includes(cur.id) ? cur.id : cur.key)); if (el && W.pages[cur.id]?.live !== false) { const sc = el.scrollTop; Promise.resolve(W.pages[cur.id].render(el, cur.key.split('/').slice(1), false, true)).then(() => { el.scrollTop = sc }) } };
let rt; W.on('change', k => { if (k === 'settings') return; clearTimeout(rt); rt = setTimeout(() => W.pages[cur?.id]?.live && W.refresh(), 150) });
W.route = route;

/* ======== حركات وسلاسة بأسلوب Flutter / Material 3 ======== */
/* عدّاد يعدّ تصاعديًا (يستخدم data-count) */
W.countUp = (root = document) => $$('[data-count]', root).forEach(e => { const to = +e.dataset.count; if (!isFinite(to) || !to) return; const t0 = performance.now(), d = 650, f = t => { const p = Math.min(1, (t - t0) / d), v = Math.round(to * (1 - Math.pow(1 - p, 3))); e.textContent = AR(v); if (p < 1) requestAnimationFrame(f) }; e.textContent = AR(0); requestAnimationFrame(f) });
/* سحب الـ Bottom Sheet للأسفل لإغلاقه */
(() => {
  const sh = $('#sheet'); let y0 = null, dy = 0, t0 = 0;
  sh.addEventListener('touchstart', e => { if (sh.scrollTop > 0 || e.target.closest('input,textarea,select')) { y0 = null; return } y0 = e.touches[0].clientY; dy = 0; t0 = performance.now() }, { passive: true });
  sh.addEventListener('touchmove', e => { if (y0 == null) return; dy = e.touches[0].clientY - y0; if (dy <= 0) { dy = 0; sh.style.transform = ''; return } sh.style.transition = 'none'; sh.style.transform = `translateY(${dy * .9}px)` }, { passive: true });
  const end = () => { if (y0 == null) return; const v = dy / Math.max(1, performance.now() - t0), close = dy > 120 || (dy > 40 && v > .6); y0 = null; sh.style.transition = 'transform .28s cubic-bezier(.2,0,0,1)'; if (close) { sh.style.transform = 'translateY(105%)'; W.hap.tick(); setTimeout(() => { closeSheet(); sh.style.transition = ''; sh.style.transform = '' }, 230) } else { sh.style.transform = ''; setTimeout(() => sh.style.transition = '', 300) } dy = 0 };
  sh.addEventListener('touchend', end); sh.addEventListener('touchcancel', end);
})();
/* Stretch overscroll (مثل stretch_effect في Flutter على أندرويد) */
(() => {
  let el = null, ly = 0, ov = 0, raf = 0;
  const apply = () => { raf = 0; if (!el) return; const s = 1 + Math.min(.06, Math.pow(Math.abs(ov) / 400, .75) * .1); el.style.transformOrigin = ov > 0 ? '50% 0' : '50% 100%'; el.style.transform = ov ? `scaleY(${s})` : '' };
  document.addEventListener('touchstart', e => { el = e.target.closest('.page.on'); if (el?.querySelector('.tpg')) el = null; if (!el) return; ly = e.touches[0].clientY; ov = 0; el.style.transition = 'none' }, { passive: true });
  document.addEventListener('touchmove', e => { if (!el) return; const y = e.touches[0].clientY, d = y - ly; ly = y; const top = el.scrollTop <= 0, bot = el.scrollTop + el.clientHeight >= el.scrollHeight - 1;
    if ((top && d > 0 && ov >= 0) || (ov > 0 && d < 0)) ov = Math.max(0, ov + d * .55); else if ((bot && d < 0 && ov <= 0) || (ov < 0 && d > 0)) ov = Math.min(0, ov + d * .55); else return;
    if (!raf) raf = requestAnimationFrame(apply) }, { passive: true });
  const end = () => { if (!el) return; const x = el; el = null; ov = 0; x.style.transition = 'transform .55s cubic-bezier(.2,1.1,.3,1)'; x.style.transform = ''; setTimeout(() => { x.style.transition = ''; x.style.transformOrigin = '' }, 600) };
  document.addEventListener('touchend', end, { passive: true }); document.addEventListener('touchcancel', end, { passive: true });
})();
