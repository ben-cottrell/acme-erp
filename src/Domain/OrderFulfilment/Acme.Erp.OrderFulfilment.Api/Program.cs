var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi("/openapi/v1.json");
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "order-fulfilment-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "order-fulfilment-api" }));
app.MapGet("/domain/fulfilment/api", (IConfiguration configuration) => Results.Ok(new
{
    service = "order-fulfilment-api",
    kind = "domain-api",
    domain = "Order Fulfilment",
    route = "/domain/fulfilment/api",
    hasDatabaseConfiguration = !string.IsNullOrWhiteSpace(configuration.GetConnectionString("DomainDatabase"))
}));

app.UseAuthorization();

app.MapControllers();

app.Run();