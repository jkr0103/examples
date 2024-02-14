From ubuntu:22.04

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-flask python3-pip gunicorn

RUN pip3 install werkzeug==2.0.3

RUN mkdir -p /gunicorn/

COPY Makefile /gunicorn/
COPY gunicorn.manifest.template /gunicorn/
COPY main.py /gunicorn/

WORKDIR /gunicorn

ENTRYPOINT ["gunicorn"]

CMD ["--timeout", "600", "main:app"]
