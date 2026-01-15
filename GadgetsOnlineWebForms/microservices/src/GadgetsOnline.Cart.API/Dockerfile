FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["GadgetsOnline.Cart.API/GadgetsOnline.Cart.API.csproj", "GadgetsOnline.Cart.API/"]
COPY ["GadgetsOnline.Shared.Contracts/GadgetsOnline.Shared.Contracts.csproj", "GadgetsOnline.Shared.Contracts/"]
RUN dotnet restore "GadgetsOnline.Cart.API/GadgetsOnline.Cart.API.csproj"
COPY . .
WORKDIR "/src/GadgetsOnline.Cart.API"
RUN dotnet build "GadgetsOnline.Cart.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GadgetsOnline.Cart.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GadgetsOnline.Cart.API.dll"]
