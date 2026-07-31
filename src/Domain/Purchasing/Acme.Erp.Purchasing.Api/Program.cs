var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi("/openapi/v1.json");
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "purchasing-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "purchasing-api" }));
app.MapGet("/domain/purchasing/api", (IConfiguration configuration) => Results.Ok(new
{
    service = "purchasing-api",
    kind = "domain-api",
    domain = "Purchasing",
    route = "/domain/purchasing/api",
    hasDatabaseConfiguration = !string.IsNullOrWhiteSpace(configuration.GetConnectionString("DomainDatabase"))
}));

app.UseAuthorization();

app.MapControllers();

app.Run();