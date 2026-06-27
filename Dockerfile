# --- Stage 1: Build & Dependencies ---
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Instalamos las dependencias en un prefijo neutral (/install) para que no dependa de /root
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Stage 2: Final Runtime ---
FROM python:3.12-slim AS runner

WORKDIR /app

# 1. Creamos un usuario del sistema sin privilegios ni password
RUN useradd -u 1001 --create-home appuser

# 2. Copiamos las dependencias al directorio estándar del sistema
COPY --from=builder /install /usr/local
COPY --from=builder /app /app

# Copiar el código fuente de la aplicación
COPY app/ ./app/

# 3. Cambiamos la propiedad de la carpeta de trabajo al nuevo usuario
RUN chown -R appuser:appuser /app

# 4. Cambiamos al contexto del usuario no-root (A partir de aquí nada es root)
USER appuser

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]