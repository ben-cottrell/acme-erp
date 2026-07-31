var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi("/openapi/v1.json");
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "sales-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "sales-api" }));
app.MapGet("/domain/sales/api", (IConfiguration configuration) => Results.Ok(new
{
    service = "sales-api",
    kind = "domain-api",
    domain = "Sales",
    route = "/domain/sales/api",
    hasDatabaseConfiguration = !string.IsNullOrWhiteSpace(configuration.GetConnectionString("DomainDatabase"))
}));

app.UseAuthorization();

app.MapControllers();

app.Run();