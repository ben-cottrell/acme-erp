var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddHttpClient("ApplicationApi", (serviceProvider, client) =>
{
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    var baseAddress = configuration["ApplicationApi:BaseUrl"] ?? "http://security-administration-api/apps/security-administration/api";
    client.BaseAddress = new Uri(baseAddress, UriKind.Absolute);
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", service = "security-administration-ui" }));
app.MapGet("/readyz", () => Results.Ok(new { status = "ready", service = "security-administration-ui" }));

app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();