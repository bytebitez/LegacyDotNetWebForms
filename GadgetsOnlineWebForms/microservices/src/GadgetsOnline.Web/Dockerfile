FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["GadgetsOnline.Web/GadgetsOnline.Web.csproj", "GadgetsOnline.Web/"]
COPY ["GadgetsOnline.Shared.Contracts/GadgetsOnline.Shared.Contracts.csproj", "GadgetsOnline.Shared.Contracts/"]
RUN dotnet restore "GadgetsOnline.Web/GadgetsOnline.Web.csproj"
COPY . .
WORKDIR "/src/GadgetsOnline.Web"
RUN dotnet build "GadgetsOnline.Web.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GadgetsOnline.Web.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GadgetsOnline.Web.dll"]
