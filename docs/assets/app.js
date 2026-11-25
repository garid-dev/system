/* GitHub Pages статик хуудасны үндсэн логик */

const params = new URLSearchParams(location.search);
/* Хуучин хадгалагдсан хаяг хоцорсон байсан тул одоо config.js дээрх хаягийг гол болгож байна. */
let API = params.get('api') || (window.SHOP_CONFIG ? window.SHOP_CONFIG.apiBase : '');
API = String(API).replace(/\/+$/, '');

let user = JSON.parse(localStorage.getItem('shop_user') || 'null');
let cart = JSON.parse(localStorage.getItem('shop_cart') || '[]');
let products = [];

/* ---------- жижиг туслах функцууд ---------- */
function showMsg(text, isError) {
    const box = document.getElementById('msg');
    box.textContent = text;
    box.className = isError ? 'msg error' : 'msg';
}
function esc(v) {
    return String(v == null ? '' : v).replace(/[&<>"']/g, c =>
        ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
function money(v) { return Number(v).toLocaleString('en-US'); }
function showError(e) {
    const m = String((e && e.message) || e || '');
    if (/failed to fetch|networkerror|load failed|network connection|http 5\d\d/i.test(m)) {
        showMsg('Холболт тасарсан байна. Хэсэг хүлээгээд дахин оролдоно уу.', true);
    } else if (/http 4\d\d/i.test(m)) {
        showMsg('Хүсэлт буруу байна. Мэдээллээ шалгаад дахин оролдоно уу.', true);
    } else {
        showMsg('Алдаа: ' + m, true);
    }
}
async function api(path, options) {
    if (!API || API.includes('REPLACE-ME')) {
        showMsg('Холболт тохируулагдаагүй байна', true);
        throw new Error('Холболтын хаяг байхгүй');
    }
    const res = await fetch(API + path, Object.assign({
        headers: { 'Content-Type': 'application/json' }
    }, options || {}));
    if (!res.ok) throw new Error('HTTP ' + res.status);
    return res.json();
}

/* ---------- хэрэглэгч ---------- */
function renderUser() {
    const loginBox = document.getElementById('loginBox');
    const userBox = document.getElementById('userBox');
    const title = document.getElementById('userTitle');
    if (user) {
        loginBox.classList.add('hidden');
        userBox.classList.remove('hidden');
        title.textContent = '👤 ' + user.username;
        document.getElementById('userNameText').textContent = user.fullName || user.username;
        document.getElementById('userRoleText').textContent = user.role || 'Customer';
    } else {
        loginBox.classList.remove('hidden');
        userBox.classList.add('hidden');
        title.textContent = '🔑 Нэвтрэх / Бүртгүүлэх';
    }
}
async function doLogin() {
    try {
        const r = await api('/api/login', {
            method: 'POST',
            body: JSON.stringify({
                username: document.getElementById('loginUser').value.trim(),
                password: document.getElementById('loginPass').value
            })
        });
        if (r.ok) {
            user = { userId: r.userId, username: r.username, fullName: r.fullName, role: r.role };
            localStorage.setItem('shop_user', JSON.stringify(user));
            showMsg(r.message);
        } else {
            showMsg(r.message, true);
        }
        renderUser();
    } catch (e) { showError(e); }
}
async function doRegister() {
    try {
        const r = await api('/api/register', {
            method: 'POST',
            body: JSON.stringify({
                username: document.getElementById('regUser').value.trim(),
                password: document.getElementById('regPass').value,
                fullName: document.getElementById('regName').value.trim(),
                email: document.getElementById('regEmail').value.trim()
            })
        });
        if (r.ok) {
            user = { userId: r.userId, username: r.username, fullName: r.fullName || r.username, role: 'Customer' };
            localStorage.setItem('shop_user', JSON.stringify(user));
            showMsg(r.message);
        } else {
            showMsg(r.message, true);
        }
        renderUser();
    } catch (e) { showError(e); }
}
function doLogout() {
    user = null;
    localStorage.removeItem('shop_user');
    renderUser();
    showMsg('Системээс гарлаа');
}

/* ---------- бараа, сагс, захиалга ---------- */
function renderProducts() {
    const body = document.getElementById('productsBody');
    document.getElementById('productCount').textContent = '(' + products.length + ')';
    if (!products.length) {
        body.innerHTML = '<tr><td colspan="6" class="empty">Бараа ачааллаж чадсангүй. Дахин оролдоно уу.</td></tr>';
        return;
    }
    body.innerHTML = products.map(p => `
        <tr>
            <td class="code">${esc(p.Code || p.code)}</td>
            <td>${esc(p.Name || p.name)}</td>
            <td>${esc(p.Category || p.category)}</td>
            <td class="money">${money(p.Price || p.price)}</td>
            <td>${esc(p.Stock || p.stock)}</td>
            <td><button class="small" onclick="addToCart(${p.Id || p.id})">＋ Сагс</button></td>
        </tr>`).join('');
}
async function loadProducts() {
    try {
        products = await api('/api/products');
        renderProducts();
    } catch (e) {
        /* Холболт тасарсан ч барааны хүснэгт хоосон байж болохгүй. */
        products = (window.SHOP_FALLBACK_PRODUCTS || []).slice();
        renderProducts();
        if (products.length) {
            showMsg('Холболт тасарсан тул барааны жагсаалтыг хадгалсан хувилбараар харууллаа.', true);
        } else {
            showError(e);
        }
    }
}
function addToCart(id) {
    const p = products.find(x => (x.Id || x.id) === id);
    if (!p) return;
    const row = {
        id: p.Id || p.id,
        code: p.Code || p.code,
        name: p.Name || p.name,
        price: Number(p.Price || p.price)
    };
    const old = cart.find(x => x.id === row.id);
    if (old) old.qty++;
    else cart.push(Object.assign({ qty: 1 }, row));
    localStorage.setItem('shop_cart', JSON.stringify(cart));
    renderCart();
    showMsg(row.name + ' сагсанд нэмэгдлээ');
}
function removeFromCart(id) {
    const row = cart.find(x => x.id === id);
    if (!row) return;
    row.qty--;
    if (row.qty <= 0) cart = cart.filter(x => x.id !== id);
    localStorage.setItem('shop_cart', JSON.stringify(cart));
    renderCart();
}
function renderCart() {
    const area = document.getElementById('cartArea');
    if (cart.length === 0) {
        area.innerHTML = '<p>Сагс хоосон байна. Дээрх "`＋ Сагс`" дарна уу.</p>';
        return;
    }
    const total = cart.reduce((sum, x) => sum + x.price * x.qty, 0);
    area.innerHTML = `
        <table>
            <thead><tr><th>Код</th><th>Бараа</th><th>Тоо</th><th class="money">Үнэ</th><th class="money">Дүн</th><th></th></tr></thead>
            <tbody>${cart.map(x => `
                <tr>
                    <td class="code">${esc(x.code)}</td>
                    <td>${esc(x.name)}</td>
                    <td>${x.qty}</td>
                    <td class="money">${money(x.price)}</td>
                    <td class="money">${money(x.price * x.qty)}</td>
                    <td><button class="minus" onclick="removeFromCart(${x.id})">−</button></td>
                </tr>`).join('')}
            </tbody>
        </table>
        <div class="total">Нийт: ${money(total)} ₮</div>
        <button onclick="placeOrder()">✅ Бараа захиалах</button>`;
}
async function placeOrder() {
    if (!user) { showMsg('Эхлээд нэвтрэх эсвэл бүртгүүлэх хэрэгтэй', true); return; }
    try {
        const r = await api('/api/order', {
            method: 'POST',
            body: JSON.stringify({
                userId: user.userId,
                items: cart.map(x => ({ id: x.id, qty: x.qty }))
            })
        });
        showMsg(r.message + (r.errors && r.errors.length ? ' | ' + r.errors.join('; ') : ''), r.ok === 0);
        if (r.ok > 0) {
            cart = [];
            localStorage.removeItem('shop_cart');
            renderCart();
            await loadProducts();
        }
    } catch (e) { showError(e); }
}

/* ---------- эхлүүлэх ---------- */
renderUser();
renderCart();
loadProducts();
