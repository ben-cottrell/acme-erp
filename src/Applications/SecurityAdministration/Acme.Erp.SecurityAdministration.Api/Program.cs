var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var consumedDomainApis = Array.Empty<string>();
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
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "security-administration-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "security-administration-api" }));
app.MapGet("/apps/security-administration/api", () => Results.Ok(new
{
    service = "security-administration-api",
    kind = "application-api",
    application = "Security Administration",
    route = "/apps/security-administration/api",
    pairedUiRoute = "/apps/security-administration/ui",
    consumedDomainApis
}));

app.UseAuthorization();

app.MapControllers();

app.Run();