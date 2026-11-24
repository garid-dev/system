using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.FileProviders;
using OnlineShopWeb;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls("http://localhost:5199");
builder.Services.AddRazorPages();
builder.Services.AddSession();

// GitHub Pages-ээс ирсэн fetch хүсэлтийг зөвшөөрнө (demo зорилгоор).
builder.Services.AddCors(options =>
    options.AddPolicy("Demo", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

// gh-pages хувилбарыг локаль дээр http://localhost:5199/demo/ хаягаар шалгахад хэрэглэнэ.
string docsPath = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "..", "docs"));
if (Directory.Exists(docsPath))
{
    var docsProvider = new PhysicalFileProvider(docsPath);
    app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = docsProvider, RequestPath = "/demo" });
    app.UseStaticFiles(new StaticFileOptions { FileProvider = docsProvider, RequestPath = "/demo" });
}

app.UseStaticFiles();
app.UseRouting();
app.UseCors("Demo");
app.UseSession();

/* ------------------- GitHub Pages -> API -> SQL Server ------------------- */

app.MapGet("/api/health", () => Results.Ok(new
{
    ok = true,
    server = "GARID",
    database = "OnlineShopDB",
    time = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
}));

app.MapGet("/api/products", () => Results.Ok(Db.Rows(@"
    SELECT p.Id, p.Code, p.Name, c.Name AS Category, p.Price, p.Stock
    FROM dbo.Products p JOIN dbo.Categories c ON c.Id = p.CategoryId
    ORDER BY p.Id")));

app.MapPost("/api/login", ([FromBody] LoginReq req) =>
{
    var r = Db.Get("EXEC dbo.sp_LoginUser @Username=@u, @Password=@p",
                   Db.P("@u", req.Username), Db.P("@p", req.Password));
    var row = r.Rows[0];
    return Results.Ok(new
    {
        ok = Convert.ToInt32(row["Ok"]) == 1,
        userId = Convert.ToInt32(row["UserId"]),
        username = row["UserName"].ToString(),
        fullName = row["FullName"].ToString(),
        role = row["Role"].ToString(),
        message = row["Message"].ToString()
    });
});

app.MapPost("/api/register", ([FromBody] RegisterReq req) =>
{
    var r = Db.Get("EXEC dbo.sp_RegisterUser @Username=@u, @Password=@p, @FullName=@n, @Email=@e",
                   Db.P("@u", req.Username), Db.P("@p", req.Password),
                   Db.P("@n", req.FullName), Db.P("@e", req.Email));
    var row = r.Rows[0];
    return Results.Ok(new
    {
        ok = Convert.ToInt32(row["Ok"]) == 1,
        userId = Convert.ToInt32(row["UserId"]),
        username = req.Username,
        message = row["Message"].ToString()
    });
});

app.MapPost("/api/order", ([FromBody] OrderReq req) =>
{
    int ok = 0;
    var errors = new List<string>();
    foreach (var line in req.Items)
    {
        var r = Db.Get("EXEC dbo.sp_PlaceOrder @UserId=@u, @ProductId=@p, @Quantity=@q",
                       Db.P("@u", req.UserId), Db.P("@p", line.Id), Db.P("@q", line.Qty));
        if (Convert.ToInt32(r.Rows[0]["Ok"]) == 1) ok++;
        else errors.Add(r.Rows[0]["Message"].ToString() ?? "Алдаа");
    }
    return Results.Ok(new
    {
        ok,
        failed = errors.Count,
        message = ok > 0 ? ok + " төрлийн бараа захиалагдлаа. SSMS руу бичигдлээ." : "Захиалга амжилтгүй",
        errors
    });
});

app.MapGet("/api/log", () => Results.Ok(Db.Rows(@"
    SELECT TOP 15
           UserName    AS UserName,
           ActionCode  AS ActionCode,
           ISNULL(ProductCode, N'-') AS ProductCode,
           ISNULL(Details, N'')      AS Details,
           AtTime      AS AtTime
    FROM dbo.ActivityLog
    ORDER BY Id DESC")));

app.MapRazorPages();

app.Run();

// API-д хүлээж авах өгөгдлийн хэлбэрүүд (C# дээр файлын төгсгөлд бичнэ)
record LoginReq(string Username, string Password);
record RegisterReq(string Username, string Password, string FullName, string Email);
record OrderLine(int Id, int Qty);
record OrderReq(int UserId, List<OrderLine> Items);
