FROM rocker/rstudio:latest

RUN yes | unminimize && \
    apt-get update && \
    apt-get install -y man-db && \
    rm -rf /var/lib/apt/lists/*
