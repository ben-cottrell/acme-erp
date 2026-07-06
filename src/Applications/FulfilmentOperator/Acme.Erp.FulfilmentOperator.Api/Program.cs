var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "OrderFulfilment", "InventoryManagement" };
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "fulfilment-operator-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "fulfilment-operator-api" }));
app.MapGet("/apps/fulfilment-operator/api", () => Results.Ok(new
{
    service = "fulfilment-operator-api",
    kind = "application-api",
    application = "Fulfilment Operator",
    route = "/apps/fulfilment-operator/api",
    pairedUiRoute = "/apps/fulfilment-operator/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();