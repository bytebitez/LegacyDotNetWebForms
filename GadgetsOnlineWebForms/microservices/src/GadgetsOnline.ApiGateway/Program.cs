using Ocelot.DependencyInjection;
using Ocelot.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Load appropriate ocelot configuration based on environment
var ocelotConfig = builder.Environment.IsProduction() ? "ocelot.Docker.json" : "ocelot.json";
builder.Configuration.AddJsonFile(ocelotConfig, optional: false, reloadOnChange: true);
builder.Services.AddOcelot(builder.Configuration);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

app.UseCors("AllowAll");
await app.UseOcelot();

app.Run();
