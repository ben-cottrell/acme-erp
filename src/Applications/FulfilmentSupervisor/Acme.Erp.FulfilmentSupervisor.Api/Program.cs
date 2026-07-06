var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "OrderFulfilment", "InventoryManagement", "Sales" };
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "fulfilment-supervisor-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "fulfilment-supervisor-api" }));
app.MapGet("/apps/fulfilment-supervisor/api", () => Results.Ok(new
{
    service = "fulfilment-supervisor-api",
    kind = "application-api",
    application = "Fulfilment Supervisor",
    route = "/apps/fulfilment-supervisor/api",
    pairedUiRoute = "/apps/fulfilment-supervisor/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();