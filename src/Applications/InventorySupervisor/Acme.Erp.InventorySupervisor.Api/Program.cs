var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "InventoryManagement", "Purchasing", "OrderFulfilment" };
foreach (var domainApiName in consumedDomainApis)
{
    builder.Services.AddHttpClient($"DomainApis:{domainApiName}", (serviceProvider, client) =>
    {
        var configuration = serviceProvider.GetRequiredService<IConfiguration>();
        var baseAddress = configuration[$"DomainApis:{domainApiName}"];
        if (!string.IsNullOrWhiteSpace(baseAddress))
        {
            client.BaseAddress = new Uri(baseAddress, UriKind.Absolute);
        }
    });
}

var app = builder.Build();

app.MapOpenApi("/openapi/v1.json");
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "inventory-supervisor-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "inventory-supervisor-api" }));
app.MapGet("/apps/inventory-supervisor/api", () => Results.Ok(new
{
    service = "inventory-supervisor-api",
    kind = "application-api",
    application = "Inventory Supervisor",
    route = "/apps/inventory-supervisor/api",
    pairedUiRoute = "/apps/inventory-supervisor/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();