FROM golang:1.22-alpine AS build
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download 2>/dev/null || true
COPY . .
RUN go mod tidy && CGO_ENABLED=0 go build -o catalogue .

FROM docker.io/redhat/ubi9:latest
RUN dnf install -y ca-certificates && dnf clean all
WORKDIR /app
COPY --from=build /app/catalogue .
EXPOSE 8002
CMD ["./catalogue"]
