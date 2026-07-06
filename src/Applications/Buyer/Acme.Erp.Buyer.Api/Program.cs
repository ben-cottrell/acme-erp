var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = new[] { "Purchasing", "InventoryManagement" };
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "buyer-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "buyer-api" }));
app.MapGet("/apps/buyer/api", () => Results.Ok(new
{
    service = "buyer-api",
    kind = "application-api",
    application = "Buyer",
    route = "/apps/buyer/api",
    pairedUiRoute = "/apps/buyer/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();