FROM python:3.12-alpine
WORKDIR /app
COPY server.py .
RUN python -m py_compile server.py
CMD ["python", "-u", "server.py"]
