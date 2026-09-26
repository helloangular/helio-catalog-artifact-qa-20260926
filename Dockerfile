FROM busybox:1.37.0
COPY VERSION /app-version
CMD ["sh", "-c", "while true; do sleep 3600; done"]
