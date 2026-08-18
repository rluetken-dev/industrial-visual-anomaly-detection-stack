FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

ARG BACKEND_SOURCE_REF=v0.2.0

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /source

RUN git clone \
    --depth 1 \
    --branch "${BACKEND_SOURCE_REF}" \
    https://github.com/rluetken-dev/industrial-visual-anomaly-detection-backend.git \
    .

RUN dotnet restore \
    src/IndustrialVisualAnomalyDetection.Api/IndustrialVisualAnomalyDetection.Api.csproj

RUN dotnet publish \
    src/IndustrialVisualAnomalyDetection.Api/IndustrialVisualAnomalyDetection.Api.csproj \
    --configuration Release \
    --output /app/publish \
    --no-restore \
    /p:UseAppHost=false


FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime

ENV ASPNETCORE_HTTP_PORTS=8080
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

USER root

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/publish .

USER app

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
    CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:8080/health/live"]

ENTRYPOINT ["dotnet", "IndustrialVisualAnomalyDetection.Api.dll"]