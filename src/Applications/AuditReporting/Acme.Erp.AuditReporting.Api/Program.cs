var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "Sales", "Purchasing", "InventoryManagement", "OrderFulfilment" };
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "audit-reporting-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "audit-reporting-api" }));
app.MapGet("/apps/audit-reporting/api", () => Results.Ok(new
{
    service = "audit-reporting-api",
    kind = "application-api",
    application = "Audit Reporting",
    route = "/apps/audit-reporting/api",
    pairedUiRoute = "/apps/audit-reporting/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();