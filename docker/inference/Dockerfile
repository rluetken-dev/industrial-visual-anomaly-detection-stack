FROM python:3.12-slim AS build

ARG INFERENCE_SOURCE_REF=v0.4.0

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV TORCH_HOME=/opt/torch-cache

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /source

RUN git clone \
    --depth 1 \
    --branch "${INFERENCE_SOURCE_REF}" \
    https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model.git \
    .

RUN python -m venv "${VIRTUAL_ENV}" \
    && python -m pip install --upgrade pip \
    && python -m pip install --requirement requirements.txt \
    && python -m pip install --no-deps .

RUN python -c "from torchvision.models import ResNet18_Weights, resnet18; resnet18(weights=ResNet18_Weights.DEFAULT)"


FROM python:3.12-slim AS runtime

ENV PATH="/opt/venv/bin:${PATH}"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TORCH_HOME=/opt/torch-cache
ENV IVAD_MEMORY_CHUNK_SIZE=4096

RUN apt-get update \
    && apt-get install --yes --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system app \
    && useradd --system --gid app --create-home app

COPY --from=build /opt/venv /opt/venv
COPY --from=build /opt/torch-cache /opt/torch-cache

WORKDIR /app

USER app

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=5 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=5)"]

CMD ["uvicorn", "industrial_visual_anomaly_detection.service.app:app", "--host", "0.0.0.0", "--port", "8000"]