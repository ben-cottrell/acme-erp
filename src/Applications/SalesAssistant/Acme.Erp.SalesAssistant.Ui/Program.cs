var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddHttpClient("ApplicationApi", (serviceProvider, client) =>
{
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    var baseAddress = configuration["ApplicationApi:BaseUrl"] ?? "http://sales-assistant-api/apps/sales-assistant/api";
    client.BaseAddress = new Uri(baseAddress, UriKind.Absolute);
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "sales-assistant-ui" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "sales-assistant-ui" }));

app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();