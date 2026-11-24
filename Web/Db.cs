using System.Data;
using Microsoft.Data.SqlClient;

namespace OnlineShopWeb;

// Сантай шууд холбогдох хамгийн энгийн хоёр арга.
public static class Db
{
    // Таны SSMS-ийн сервер. Windows Authentication = нууц үг кодод байхгүй.
    const string Conn = "Server=GARID;Database=OnlineShopDB;Integrated Security=True;TrustServerCertificate=True;Encrypt=True;";

    // SELECT унших -> хүснэгт буцаана
    public static DataTable Get(string sql, params SqlParameter[] args)
    {
        using var con = new SqlConnection(Conn);
        using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddRange(args);
        using var adapter = new SqlDataAdapter(cmd);
        var table = new DataTable();
        adapter.Fill(table);
        return table;
    }

    // SELECT-ийг JSON-д бэлэн мөр болгох (API-д хэрэглэнэ)
    public static List<Dictionary<string, object?>> Rows(string sql, params SqlParameter[] args)
    {
        var table = Get(sql, args);
        var list = new List<Dictionary<string, object?>>();
        foreach (DataRow row in table.Rows)
        {
            var item = new Dictionary<string, object?>();
            foreach (DataColumn col in table.Columns)
                item[col.ColumnName] = row[col] == DBNull.Value ? null : row[col];
            list.Add(item);
        }
        return list;
    }

    // INSERT / UPDATE / DELETE бичих
    public static int Run(string sql, params SqlParameter[] args)
    {
        using var con = new SqlConnection(Conn);
        using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddRange(args);
        con.Open();
        return cmd.ExecuteNonQuery();
    }

    // SQL-д утга дамжуулах жижиг туслах арга
    public static SqlParameter P(string name, object? value) => new(name, value ?? DBNull.Value);
}
