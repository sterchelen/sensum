#Dependencies builder
FROM python:3.8-slim AS builder
RUN apt-get update
RUN apt-get install -y --no-install-recommends build-essential gcc

COPY requirements.txt .
RUN pip install --upgrade pip
#Wheel dependencies
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt


#API runner
FROM python:3.8-slim AS runner

ENV APP_HOME=/home/app/web
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY --from=builder /usr/src/app/wheels /wheels
RUN pip install --upgrade pip
RUN pip install --no-cache /wheels/*
COPY api.py wsgi.py ./

EXPOSE 8080/tcp

CMD ["sh", "-c", "exec gunicorn -b 0.0.0.0:8080 wsgi"]
