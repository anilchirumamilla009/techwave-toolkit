# .NET 8 + ASP.NET Core Web API Scaffold

## Directory tree

```
<ProjectName>/
├── src/
│   └── <ProjectName>/
│       ├── Controllers/
│       │   └── HealthController.cs
│       ├── Middleware/
│       │   └── ErrorHandlingMiddleware.cs
│       ├── Models/
│       │   └── ErrorResponse.cs
│       ├── Program.cs
│       ├── <ProjectName>.csproj
│       ├── appsettings.json
│       └── appsettings.Development.json
├── tests/
│   └── <ProjectName>.Tests/
│       ├── Controllers/
│       │   └── HealthControllerTests.cs
│       └── <ProjectName>.Tests.csproj
├── Dockerfile
├── .gitignore
└── .env.example
```

---

## `src/<ProjectName>/<ProjectName>.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.6.2" />
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="8.0.0" />
  </ItemGroup>
</Project>
```

---

## `src/<ProjectName>/Program.cs`

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<ErrorHandlingMiddleware>();
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();

public partial class Program { }
```

The `public partial class Program` declaration is required for `WebApplicationFactory<Program>` in integration tests.

---

## `src/<ProjectName>/Controllers/HealthController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;

namespace <ProjectName>.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public IActionResult Get() =>
        Ok(new { status = "healthy", timestamp = DateTimeOffset.UtcNow });
}
```

---

## `src/<ProjectName>/Middleware/ErrorHandlingMiddleware.cs`

```csharp
using System.Net;
using System.Text.Json;
using <ProjectName>.Models;

namespace <ProjectName>.Middleware;

public class ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled exception");
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            context.Response.ContentType = "application/json";
            var error = new ErrorResponse("An unexpected error occurred.");
            await context.Response.WriteAsync(JsonSerializer.Serialize(error));
        }
    }
}
```

---

## `src/<ProjectName>/Models/ErrorResponse.cs`

```csharp
namespace <ProjectName>.Models;

public record ErrorResponse(string Message);
```

---

## `src/<ProjectName>/appsettings.json`

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

---

## `src/<ProjectName>/appsettings.Development.json`

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  }
}
```

---

## `tests/<ProjectName>.Tests/<ProjectName>.Tests.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.0.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.9.0" />
    <PackageReference Include="xunit" Version="2.7.0" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.5.7" />
    <PackageReference Include="Moq" Version="4.20.70" />
    <PackageReference Include="FluentAssertions" Version="6.12.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\<ProjectName>\<ProjectName>.csproj" />
  </ItemGroup>
</Project>
```

---

## `tests/<ProjectName>.Tests/Controllers/HealthControllerTests.cs`

```csharp
using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using FluentAssertions;

namespace <ProjectName>.Tests.Controllers;

public class HealthControllerTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Get_ReturnsOk_WithHealthyStatus()
    {
        var response = await _client.GetAsync("/api/health");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadAsStringAsync();
        body.Should().Contain("healthy");
    }
}
```

---

## `Dockerfile`

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY src/<ProjectName>/<ProjectName>.csproj ./
RUN dotnet restore

COPY src/<ProjectName>/ ./
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "<ProjectName>.dll"]
```

---

## `.gitignore` additions

```
# .NET
bin/
obj/
*.user
.vs/
```

---

## `.env.example`

```
ASPNETCORE_ENVIRONMENT=Development
# DATABASE_CONNECTION_STRING=Server=localhost;Database=mydb;User Id=myuser;Password=mypassword;
# JWT_SECRET=replace-with-a-long-random-secret
```

---

## Getting started

```bash
# Restore and run
dotnet restore
dotnet run --project src/<ProjectName>

# Run tests
dotnet test

# Build and publish
dotnet publish -c Release

# Docker
docker build -t <projectname>:latest .
docker run -p 8080:8080 <projectname>:latest
```

Swagger UI available at `http://localhost:<port>/swagger` in Development environment.

---

## Tech Stack Config example

```markdown
## Backend
- Language: C# (.NET 8)
- Framework: ASP.NET Core Web API
- Test runner: xUnit + WebApplicationFactory
- Package manager: NuGet (dotnet CLI)
```
