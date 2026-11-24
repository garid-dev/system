using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace OnlineShopWeb.Pages;

// Сагсны нэг мөр
public class CartItem
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public int Qty { get; set; }
    public decimal Price { get; set; }
    public decimal Sum => Price * Qty;
}

public class IndexModel : PageModel
{
    public DataTable Products { get; private set; } = new();
    public List<CartItem> Cart { get; private set; } = new();

    public string UserName => HttpContext.Session.GetString("User") ?? "";
    public string Role => HttpContext.Session.GetString("Role") ?? "";
    public string Message { get; private set; } = "";
    public decimal CartTotal => Cart.Sum(x => x.Sum);

    public void OnGet()
    {
        Message = TempData["Msg"]?.ToString() ?? "";
        Load();
    }

    void Load()
    {
        Products = Db.Get(@"
            SELECT p.Id, p.Code, p.Name, c.Name AS Category, p.Price, p.Stock
            FROM dbo.Products p JOIN dbo.Categories c ON c.Id = p.CategoryId
            ORDER BY p.Id");
        Cart = ReadCart();
    }

    // Сагсийг Session-д "1:2|7:1" хэлбэрээр хадгална.
    List<CartItem> ReadCart()
    {
        var list = new List<CartItem>();
        string raw = HttpContext.Session.GetString("Cart") ?? "";
        foreach (string part in raw.Split('|', StringSplitOptions.RemoveEmptyEntries))
        {
            string[] bits = part.Split(':');
            if (bits.Length != 2) continue;
            if (!int.TryParse(bits[0], out int id) || !int.TryParse(bits[1], out int qty)) continue;

            var t = Db.Get("SELECT Code, Name, Price FROM dbo.Products WHERE Id = @id", Db.P("@id", id));
            if (t.Rows.Count == 0) continue;
            var r = t.Rows[0];
            list.Add(new CartItem
            {
                Id = id,
                Code = r["Code"].ToString()!,
                Name = r["Name"].ToString()!,
                Price = Convert.ToDecimal(r["Price"]),
                Qty = qty
            });
        }
        return list;
    }

    void SaveCart(List<CartItem> cart)
    {
        HttpContext.Session.SetString("Cart", string.Join("|", cart.Select(x => $"{x.Id}:{x.Qty}")));
    }

    // ---- Хэрэглэгч ----
    public IActionResult OnPostLogin(string username, string password)
    {
        var r = Db.Get("EXEC dbo.sp_LoginUser @Username=@u, @Password=@p",
                       Db.P("@u", username), Db.P("@p", password));
        var row = r.Rows[0];
        if (Convert.ToInt32(row["Ok"]) == 1)
        {
            HttpContext.Session.SetString("User", row["UserName"].ToString()!);
            HttpContext.Session.SetString("Role", row["Role"].ToString()!);
            HttpContext.Session.SetInt32("UserId", Convert.ToInt32(row["UserId"]));
            TempData["Msg"] = "Амжилттай нэвтрэв: " + row["UserName"] + " (LOGIN лог бичигдлээ)";
        }
        else
        {
            TempData["Msg"] = row["Message"].ToString();
        }
        return RedirectToPage();
    }

    public IActionResult OnPostRegister(string regUsername, string regPassword, string regFullName, string regEmail)
    {
        var r = Db.Get("EXEC dbo.sp_RegisterUser @Username=@u, @Password=@p, @FullName=@n, @Email=@e",
                       Db.P("@u", regUsername), Db.P("@p", regPassword),
                       Db.P("@n", regFullName), Db.P("@e", regEmail));
        var row = r.Rows[0];
        if (Convert.ToInt32(row["Ok"]) == 1)
        {
            HttpContext.Session.SetString("User", regUsername);
            HttpContext.Session.SetString("Role", "Customer");
            HttpContext.Session.SetInt32("UserId", Convert.ToInt32(row["UserId"]));
            TempData["Msg"] = "Бүртгэл амжилттай (REGISTER лог бичигдлээ)";
        }
        else
        {
            TempData["Msg"] = row["Message"].ToString();
        }
        return RedirectToPage();
    }

    public IActionResult OnPostLogout()
    {
        HttpContext.Session.Remove("User");
        HttpContext.Session.Remove("Role");
        HttpContext.Session.Remove("UserId");
        HttpContext.Session.Remove("Cart");
        TempData["Msg"] = "Системээс гарлаа";
        return RedirectToPage();
    }

    // ---- Сагс ----
    public IActionResult OnPostAdd(int id)
    {
        var cart = ReadCart();
        var item = cart.FirstOrDefault(x => x.Id == id);
        if (item != null)
        {
            item.Qty++;
        }
        else
        {
            var t = Db.Get("SELECT Code, Name, Price FROM dbo.Products WHERE Id = @id", Db.P("@id", id));
            if (t.Rows.Count == 0)
            {
                TempData["Msg"] = "Бараа олдсонгүй";
                return RedirectToPage();
            }
            var r = t.Rows[0];
            cart.Add(new CartItem
            {
                Id = id,
                Code = r["Code"].ToString()!,
                Name = r["Name"].ToString()!,
                Price = Convert.ToDecimal(r["Price"]),
                Qty = 1
            });
        }
        SaveCart(cart);
        TempData["Msg"] = "Сагсанд нэмлээ";
        return RedirectToPage();
    }

    public IActionResult OnPostRemove(int id)
    {
        var cart = ReadCart();
        var item = cart.FirstOrDefault(x => x.Id == id);
        if (item != null)
        {
            item.Qty--;
            if (item.Qty <= 0) cart.Remove(item);
            SaveCart(cart);
        }
        return RedirectToPage();
    }

    // ---- Захиалга ----
    public IActionResult OnPostOrder()
    {
        int? uid = HttpContext.Session.GetInt32("UserId");
        if (uid is null)
        {
            TempData["Msg"] = "Эхлээд нэвтрэх эсвэл бүртгүүлэх хэрэгтэй";
            return RedirectToPage();
        }

        var cart = ReadCart();
        if (cart.Count == 0)
        {
            TempData["Msg"] = "Сагс хоосон байна";
            return RedirectToPage();
        }

        int ok = 0;
        foreach (var item in cart)
        {
            var r = Db.Get("EXEC dbo.sp_PlaceOrder @UserId=@u, @ProductId=@p, @Quantity=@q",
                           Db.P("@u", uid.Value), Db.P("@p", item.Id), Db.P("@q", item.Qty));
            if (Convert.ToInt32(r.Rows[0]["Ok"]) == 1) ok++;
        }
        HttpContext.Session.Remove("Cart");
        TempData["Msg"] = ok + " төрлийн бараа захиалагдлаа. Доорх Live логоос шууд харна уу.";
        return RedirectToPage();
    }
}
