var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "Sales", "InventoryManagement" };
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "sales-assistant-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "sales-assistant-api" }));
app.MapGet("/apps/sales-assistant/api", () => Results.Ok(new
{
    service = "sales-assistant-api",
    kind = "application-api",
    application = "Sales Assistant",
    route = "/apps/sales-assistant/api",
    pairedUiRoute = "/apps/sales-assistant/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();