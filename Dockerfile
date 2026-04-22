FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    exiftool \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FLASK_APP=app
ENV FLASK_ENV=production
ENV SECRET_KEY=$(python -c "import secrets; print(secrets.token_hex(32))")

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "app:app"]