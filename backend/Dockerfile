# Imagen oficial de Dart para compilar el backend en binario nativo
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Imagen de ejecución mínima y ultra ligera (~30MB)
FROM dart:stable-runtime

COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
CMD ["/app/bin/server"]
