# ── Aşama 1: Flutter Web Derlemesi ──
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

# ── Aşama 2: Statik Dosyaları Nginx ile Sun ──
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
