FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["GadgetsOnline.ApiGateway/GadgetsOnline.ApiGateway.csproj", "GadgetsOnline.ApiGateway/"]
RUN dotnet restore "GadgetsOnline.ApiGateway/GadgetsOnline.ApiGateway.csproj"
COPY . .
WORKDIR "/src/GadgetsOnline.ApiGateway"
RUN dotnet build "GadgetsOnline.ApiGateway.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GadgetsOnline.ApiGateway.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GadgetsOnline.ApiGateway.dll"]
