# Production-grade lightweight Nginx image
FROM nginxinc/nginx-unprivileged:alpine-slim

LABEL maintainer="FMS DevOps Team"
LABEL description="Custom Error Pages for Traefik Ingress Gateway (Kubiverse Theme)"

# Copy custom Nginx configuration
COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

# Copy static web assets
COPY --chown=nginx:nginx src/ /usr/share/nginx/html/

# Expose unprivileged port 8080
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/healthz || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
