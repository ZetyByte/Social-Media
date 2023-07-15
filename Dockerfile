# Stage 1: Build Flutter app
FROM openjdk:8-jdk as flutter_builder

# Install Flutter SDK dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor

# Set up the Flutter app
WORKDIR /app
COPY social_media /app

# Build the Flutter app
RUN flutter build apk --release

# Stage 2: Build ASP.NET WebAPI app
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS dotnet_builder

# Set up the ASP.NET app
WORKDIR /app
COPY API/API /app

# Build the ASP.NET app
RUN dotnet publish -c Release -o out

# Stage 3: Final image
FROM mcr.microsoft.com/dotnet/aspnet:7.0

# Set up the runtime environment for ASP.NET app
WORKDIR /app
COPY --from=dotnet_builder /app/out .

# Copy the built Flutter app to the ASP.NET app's wwwroot folder
COPY --from=flutter_builder /app/build/app/outputs/apk/release/app-release.apk /app/wwwroot/app-release.apk

# Expose the necessary ports
EXPOSE 80

# Set the entry point for the container
ENTRYPOINT ["dotnet", "API.dll"]
