FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY Acme.Erp.slnx ./
COPY src ./src
RUN dotnet restore "src/Purchasing/Acme.Erp.Purchasing.Ui/Acme.Erp.Purchasing.Ui.csproj"
RUN dotnet publish "src/Purchasing/Acme.Erp.Purchasing.Ui/Acme.Erp.Purchasing.Ui.csproj" -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM runtime AS final
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "Acme.Erp.Purchasing.Ui.dll"]
