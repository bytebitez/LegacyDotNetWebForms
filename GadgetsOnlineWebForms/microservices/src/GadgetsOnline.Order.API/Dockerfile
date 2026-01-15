FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["GadgetsOnline.Order.API/GadgetsOnline.Order.API.csproj", "GadgetsOnline.Order.API/"]
COPY ["GadgetsOnline.Shared.Contracts/GadgetsOnline.Shared.Contracts.csproj", "GadgetsOnline.Shared.Contracts/"]
RUN dotnet restore "GadgetsOnline.Order.API/GadgetsOnline.Order.API.csproj"
COPY . .
WORKDIR "/src/GadgetsOnline.Order.API"
RUN dotnet build "GadgetsOnline.Order.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GadgetsOnline.Order.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GadgetsOnline.Order.API.dll"]
