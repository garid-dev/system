using System.Data;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace OnlineShopWeb.Pages;

// Энэ хуудас 4 секунд тутамд өөрөө дахин ачааллаж, лог шинээр уншина.
public class LogModel : PageModel
{
    public DataTable Items { get; private set; } = new();

    public void OnGet()
    {
        ViewData["Refresh"] = "4";
        Items = Db.Get(@"
            SELECT TOP 15
                   UserName    AS [Хэрэглэгч],
                   ActionCode  AS [Код],
                   ISNULL(ProductCode, N'-') AS [Барааны код],
                   ISNULL(Details, N'')      AS [Үйлдэл],
                   AtTime      AS [Огноо / цаг]
            FROM dbo.ActivityLog
            ORDER BY Id DESC");
    }
}
