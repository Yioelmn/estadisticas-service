# --- Stage 1: Build & Dependencies ---
FROM python:3.12-slim AS builder

WORKDIR /app

# Instalar herramientas de compilación si fueran necesarias por las dependencias
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copiar requerimientos e instalar dependencias en el espacio de usuario o ruta local
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# --- Stage 2: Final Runtime ---
FROM python:3.12-slim AS runner

WORKDIR /app

# Copiar las dependencias instaladas desde el stage anterior
COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app

# Asegurar que los scripts instalados por pip estén en el PATH
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Copiar el código fuente de la aplicación
COPY app/ ./app/

# Exponer el puerto por defecto de FastAPI/Uvicorn
EXPOSE 8000

# Comando para ejecutar la aplicación en producción
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]