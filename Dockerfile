# ETAPA 1: builder, instala dependencias Python
FROM python:3.11-slim AS builder
WORKDIR /app
# Instalar dependencias del sistema necesarias para compilar
RUN apt-get update && apt-get install -y --no-install-recommends \
gcc \
&& rm -rf /var/lib/apt/lists/*
# Limpiar /var/lib/apt/lists/ Para no dejar caché de apt en la imagen final
COPY requirements.txt ./
# Instalamos en un directorio específico para copiarlo después
RUN pip install --upgrade pip && \
pip install --prefix=/install --no-cache-dir -r requirements.txt

# ETAPA 2: imagen de producción
FROM python:3.11-slim AS production
WORKDIR /app
# Crear usuario no-root
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
# Copiamos los paquetes instalados desde el builder
COPY --from=builder /install /usr/local
# Copiamos el código de la aplicación
COPY app.py ./
COPY templates/ ./templates/
# Asignamos propiedad al usuario no-root
RUN chown -R appuser:appgroup /app
USER appuser
# Puerto que usa Flask
EXPOSE 5000
# Healthcheck para el frontend
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
CMD wget -qO- http://localhost:5000/ || exit 1
# En producción no se usa Flask, se usa gunicorn
# El servidor de Flask no está diseñado para producción
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]