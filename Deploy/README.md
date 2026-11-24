# GitHub Pages → Cloudflare → SQL Server

Энэ хавтас нь **GitHub Pages дээрх статик сайтыг** таны компьютер дээрх **SQL Server GARID / OnlineShopDB**-тэй холбох жижиг скриптүүдийг агуулна.

> GitHub Pages өөрөө C# / ASP.NET ажиллуулж чаддаггүй, мөн таны локаль SQL Server руу шууд хандаж чаддаггүй. Тиймээс бид **Cloudflare tunnel** ашиглан локаль API-г интернэтэд гаргаж, Pages-ийн хуудас тэр API руу `fetch` хийдэг.

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

## 2. Cloudflare tunnel асаана

**Терминал 2** дээр:

```powershell
cd "C:\Users\dell\Documents\Default Project\OnlineShop"
powershell -ExecutionPolicy Bypass -File Deploy\start-tunnel.ps1
```

Дэлгэцэнд ийм мөр гарч ирнэ:

```text
https://abcd-1234-efgh.trycloudflare.com
```

Энэ бол таны **API хаяг** юм.

---

## 3. Холболтыг сайтад хэлж өгнө

Сайт дээр хаяг оруулах талбар байхгүй болсон тул дараах хоёр аргын аль нь ч болно.

### Арга А — скриптээр (санал болгож байна)

**Терминал 3** дээр:

```powershell
cd "C:\Users\dell\Documents\Default Project\OnlineShop"
powershell -ExecutionPolicy Bypass -File Deploy\set-api-url.ps1 -Url https://abcd-1234-efgh.trycloudflare.com
```

Дараа нь GitHub Pages хуудсаа **hard refresh** хийнэ (`Ctrl + F5`).

### Арга Б — URL-ээр шууд

Сайтаа ийм хаягаар нээнэ:

```text
https://garid-dev.github.io/system/?api=https://abcd-1234-efgh.trycloudflare.com
```

Хаяг автоматаар `localStorage` руу хадгалагдана.

---

## 4. Шалгах

1. `https://abcd-1234-efgh.trycloudflare.com/api/health` — `ok: true` гэж хариулна.
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

- **Quick tunnel URL дахин асаах бүрт өөрчлөгддөг.** Өөрчлөгдсөн бол 3-р алхамыг дахин хийнэ үү.
- Тогтмол хаяг хэрэгтэй бол Cloudflare данс + домэйн ашиглан **named tunnel** тохируулах шаардлагатай.
- Энэ нь **зөвхөн хичээлийн demo** зориулсан тохиргоо. API бүх origin-оос хүсэлт хүлээж авдаг (`AllowAnyOrigin`) тул бодит системд хэрэглэж болохгүй.
- Компьютер унтарсан, API эсвэл tunnel зогссон үед Pages хуудасны захиалга бичигдэхгүй.

---

## Файлууд

| Файл | Юу хийдэг вэ |
|---|---|
| `cloudflared.exe` | Локаль портыг интернэтэд гаргах Cloudflare програм |
| `start-api.ps1` | ASP.NET API-г `localhost:5199` дээр асаана |
| `start-tunnel.ps1` | Cloudflare quick tunnel асаана |
| `set-api-url.ps1` | гарсан URL-ийг `docs/assets/config.js` руу бичнэ |
