# GitHub Pages → Tunnel → SQL Server

Энэ хавтас нь **GitHub Pages дээрх статик сайтыг** таны компьютер дээрх **SQL Server GARID / OnlineShopDB**-тэй холбох жижиг скриптүүдийг агуулна.

> GitHub Pages өөрөө C# / ASP.NET ажиллуулж чаддаггүй, мөн таны локаль SQL Server руу шууд хандаж чаддаггүй. Тиймээс локаль API-г түр tunnel-ээр интернэтэд гаргаж, Pages-ийн хуудас тэр API руу `fetch` хийдэг. Одоогоор **localhost.run (SSH)** ашиглаж байна — Cloudflare quick tunnel нь 429 алдаа өгсөн тул сольсон.

---

## 1. Эхлээд SQL Server болон API-г асаана

**Терминал 1** дээр:

```powershell
cd "C:\Users\dell\Documents\Default Project\OnlineShop"
powershell -ExecutionPolicy Bypass -File Deploy\start-api.ps1
```

Амжилттай бол:

```text
Now listening on: http://localhost:5199
```

гарч ирнэ. Энэ үед API `GARID / OnlineShopDB` руу шууд холбогдоно.

---

## 2. Tunnel асаана

**Терминал 2** дээр:

```powershell
cd "C:\Users\dell\Documents\Default Project\OnlineShop"
powershell -ExecutionPolicy Bypass -File Deploy\start-tunnel-localhostrun.ps1
```

Дэлгэцэнд ийм мөр гарч ирнэ:

```text
f9692460835cdb.app.lhr.life tunneled with tls termination, https://f9692460835cdb.app.lhr.life
```

Энэ бол таны **API хаяг** юм. Энэ цонхыг хааж болохгүй — хаавал холболт тасарна.

> Хуучин `Deploy\start-tunnel.ps1` (Cloudflare) одоо 429 алдаа өгч байна. Хэрэв дараа нь дахин ажиллавал сонголтоор хэрэглэж болно.

---

## 3. Холболтыг сайтад хэлж өгнө

Сайт дээр хаяг оруулах талбар байхгүй болсон тул дараах хоёр аргын аль нь ч болно.

### Арга А — скриптээр (санал болгож байна)

**Терминал 3** дээр:

```powershell
cd "C:\Users\dell\Documents\Default Project\OnlineShop"
powershell -ExecutionPolicy Bypass -File Deploy\set-api-url.ps1 -Url https://f9692460835cdb.app.lhr.life
```

Дараа нь GitHub Pages хуудсаа **hard refresh** хийнэ (`Ctrl + F5`).

### Арга Б — URL-ээр шууд

Сайтаа ийм хаягаар нээнэ:

```text
https://garid-dev.github.io/system/?api=https://f9692460835cdb.app.lhr.life
```

Энэ арга нь зөвхөн тухайн нээлтэд хүчинтэй. Байнгийн хаяг `docs\assets\config.js` дотор байна.

---

## 4. Шалгах

1. `https://f9692460835cdb.app.lhr.life/api/health` — `ok: true` гэж хариулна.
2. GitHub Pages хуудас дээр 12 бараа харагдана.
3. `bold / bold123` эсвэл `admin / admin123` гэж нэвтрэнэ.
4. Бараа нэмээд **Бараа захиалах** дарна. Амжилттай бол мэдэгдэл гарч, сагс хоосоно.
5. SSMS дээр дараах query-г ажиллуулж баталгаажуулна:

```sql
SELECT TOP 5 UserName, ActionCode, ProductCode, Details, AtTime
FROM dbo.ActivityLog
ORDER BY Id DESC;
```

---

## чухал анхааруулга

- **Үнэгүй tunnel URL хэдхэн цагийн дараа өөрчлөгддөг.** Өөрчлөгдсөн бол 2, 3-р алхамыг дахин хийнэ үү.
- Тогтмол хаяг хэрэгтэй бол localhost.run данс + SSH key, эсвэл Cloudflare данс + домэйн (named tunnel) ашиглах шаардлагатай.
- Энэ нь **зөвхөн хичээлийн demo** зориулсан тохиргоо. API бүх origin-оос хүсэлт хүлээж авдаг (`AllowAnyOrigin`) тул бодит системд хэрэглэж болохгүй.
- Компьютер унтарсан, API эсвэл tunnel зогссон үед Pages хуудасны захиалга бичигдэхгүй. Барааны жагсаалт `docs/assets/products-fallback.js`-ээс харагдаж байна (зөвхөн харагдацад зориулсан хуулбар).
- GitHub buildlog дээр гардаг `Node.js 20 is deprecated ... actions/upload-artifact@v4` гэсэн мөр **GitHub-ийн дотоод Pages build-ийн анхааруулга** юм. Энэ репозиторт `.github/workflows` байхгүй, build статус `built` байна — алдаа биш тул засах шаардлагагүй.

---

## Файлууд

| Файл | Юу хийдэг вэ |
|---|---|
| `cloudflared.exe` | Локаль портыг интернэтэд гаргах Cloudflare програм |
| `start-api.ps1` | ASP.NET API-г `localhost:5199` дээр асаана |
| `start-tunnel.ps1` | Cloudflare quick tunnel асаана |
| `set-api-url.ps1` | гарсан URL-ийг `docs/assets/config.js` руу бичнэ |
