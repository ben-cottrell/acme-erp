var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi("/openapi/v1.json");
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "inventory-management-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "inventory-management-api" }));
app.MapGet("/domain/inventory/api", (IConfiguration configuration) => Results.Ok(new
{
    service = "inventory-management-api",
    kind = "domain-api",
    domain = "Inventory Management",
    route = "/domain/inventory/api",
    hasDatabaseConfiguration = !string.IsNullOrWhiteSpace(configuration.GetConnectionString("DomainDatabase"))
}));

app.UseAuthorization();

app.MapControllers();

app.Run();