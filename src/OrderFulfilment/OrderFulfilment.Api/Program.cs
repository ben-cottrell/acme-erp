var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi("/openapi/v1.json");
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "order-fulfilment-api" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "order-fulfilment-api" }));

app.UseAuthorization();

app.MapControllers();

app.Run();
