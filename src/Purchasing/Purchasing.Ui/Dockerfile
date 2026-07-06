FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY Acme.Erp.sln ./
COPY src ./src
RUN dotnet restore "src/Purchasing/Purchasing.Ui/Purchasing.Ui.csproj"
RUN dotnet publish "src/Purchasing/Purchasing.Ui/Purchasing.Ui.csproj" -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM runtime AS final
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "Purchasing.Ui.dll"]
