# GMP-WHO Backend API
# Built on .NET 8

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file (when building from GMP_System/GMP_System/ directory)
COPY ["GMP_System.csproj", "./"]
RUN dotnet restore "GMP_System.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "GMP_System.csproj" -c Release -o /app/build
RUN dotnet publish "GMP_System.csproj" -c Release -o /app/publish

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Install curl for healthcheck
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

# Configure ASP.NET Core to listen on port 5000
ENV ASPNETCORE_URLS=http://0.0.0.0:5000

# Copy published files
COPY --from=build /app/publish .

# Expose port
EXPOSE 5000

# Entry point
ENTRYPOINT ["dotnet", "GMP_System.dll"]
