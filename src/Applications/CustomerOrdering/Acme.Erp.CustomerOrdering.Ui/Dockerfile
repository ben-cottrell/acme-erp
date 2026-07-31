FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY Directory.Build.props ./
COPY .editorconfig .globalconfig ./
COPY Acme.Erp.slnx ./
COPY src ./src
RUN dotnet restore "src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Ui/Acme.Erp.CustomerOrdering.Ui.csproj"
RUN dotnet publish "src/Applications/CustomerOrdering/Acme.Erp.CustomerOrdering.Ui/Acme.Erp.CustomerOrdering.Ui.csproj" -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM runtime AS final
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "Acme.Erp.CustomerOrdering.Ui.dll"]