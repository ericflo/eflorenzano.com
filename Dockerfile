# syntax=docker/dockerfile:1
#
# Self-contained static server for eflorenzano.com.
#
#   docker build -t eflorenzano .
#   docker run --rm -p 8080:8080 eflorenzano
#
# Runs nginx as an unprivileged user on port 8080, so it needs no root and no
# extra files — the config lives in this Dockerfile.

FROM nginx:1.27-alpine

# Replace the stock config wholesale. Everything nginx needs to write goes to
# /tmp so the whole filesystem can stay read-only under an unprivileged user.
COPY <<'NGINX_CONF' /etc/nginx/nginx.conf
worker_processes auto;
pid /tmp/nginx.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    access_log    /dev/stdout;

    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;

    sendfile      on;
    tcp_nopush    on;
    server_tokens off;

    # woff2, jpg, png and ico are already compressed — gzipping them wastes CPU.
    gzip              on;
    gzip_vary         on;
    gzip_min_length   256;
    gzip_types        text/css application/javascript image/svg+xml application/json text/plain;

    server {
        listen      8080;
        server_name _;
        root        /usr/share/nginx/html;
        index       index.html;

        # Set at server level only. A location that declares its own add_header
        # drops every inherited one, so caching below uses `expires` instead.
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; img-src 'self' data: https://www.googletagmanager.com https://*.google-analytics.com; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com; connect-src 'self' https://*.google-analytics.com https://*.analytics.google.com https://*.googletagmanager.com; style-src 'self'; font-src 'self'" always;

        location / {
            try_files $uri $uri/ =404;
        }

        # HTML revalidates every time so content edits go live on deploy.
        location = /            { expires -1; }
        location ~* \.html$     { expires -1; }

        # Assets are versioned by hand (global.css?v=2), so cache them hard.
        location ^~ /media/     { expires 30d; access_log off; }
        location = /favicon.ico { expires 7d;  access_log off; }
    }
}
NGINX_CONF

COPY index.html favicon.ico /usr/share/nginx/html/
COPY media/ /usr/share/nginx/html/media/

USER nginx
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=2s \
    CMD wget -qO /dev/null http://127.0.0.1:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
