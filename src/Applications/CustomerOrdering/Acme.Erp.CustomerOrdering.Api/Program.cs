var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "Sales", "InventoryManagement", "OrderFulfilment" };
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "customer-ordering-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "customer-ordering-api" }));
app.MapGet("/apps/customer-ordering/api", () => Results.Ok(new
{
    service = "customer-ordering-api",
    kind = "application-api",
    application = "Customer Ordering",
    route = "/apps/customer-ordering/api",
    pairedUiRoute = "/apps/customer-ordering/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();