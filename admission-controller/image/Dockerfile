FROM python:3.8-slim

COPY ./src /
WORKDIR /src
RUN pip3 install -r requirements.txt
CMD ["python3", "mutate-manifest.py"]