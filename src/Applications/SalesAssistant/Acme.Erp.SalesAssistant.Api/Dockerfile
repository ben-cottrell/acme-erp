FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY Directory.Build.props ./
COPY Acme.Erp.slnx ./
COPY src ./src
RUN dotnet restore "src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Api/Acme.Erp.SalesAssistant.Api.csproj"
RUN dotnet publish "src/Applications/SalesAssistant/Acme.Erp.SalesAssistant.Api/Acme.Erp.SalesAssistant.Api.csproj" -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM runtime AS final
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "Acme.Erp.SalesAssistant.Api.dll"]