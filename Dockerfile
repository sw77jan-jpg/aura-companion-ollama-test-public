# Minimal AURA companion FastAPI — listens on $PORT for Railway
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    AURA_HOST=0.0.0.0 \
    AURA_EMBEDDING=hash

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir -r requirements.txt

# Prefer plain source if present; else decode split/base64 gzip fallbacks
COPY aura_universal_enhanced.py* ./
COPY aura_chunk_*.b64w* ./
COPY aura_part_*.b64w* ./
RUN set -e; \
  if [ -f aura_universal_enhanced.py ]; then \
    echo "using plain aura_universal_enhanced.py"; \
  elif [ -f aura_universal_enhanced.py.gz.b64 ]; then \
    base64 -d aura_universal_enhanced.py.gz.b64 | gunzip > aura_universal_enhanced.py; \
  elif ls aura_part_*.b64w >/dev/null 2>&1; then \
    cat aura_part_*.b64w | tr -d '\n' | base64 -d | gunzip > aura_universal_enhanced.py; \
  elif ls aura_chunk_*.b64w >/dev/null 2>&1; then \
    cat aura_chunk_*.b64w | tr -d '\n' | base64 -d | gunzip > aura_universal_enhanced.py; \
  elif ls aura_part_*.b64 >/dev/null 2>&1; then \
    cat aura_part_*.b64 | tr -d '\n' | base64 -d | gunzip > aura_universal_enhanced.py; \
  else \
    echo "ERROR: no companion source in build context" >&2; exit 1; \
  fi; \
  rm -f aura_universal_enhanced.py.gz.b64 aura_chunk_*.b64w aura_part_*.b64w aura_part_*.b64; \
  test -s aura_universal_enhanced.py
COPY README_COMPANION_OLLAMA.md* ./

EXPOSE 8080
CMD ["sh", "-c", "exec python aura_universal_enhanced.py --host 0.0.0.0 --port ${PORT:-8080}"]
