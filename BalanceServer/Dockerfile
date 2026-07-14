FROM golang:1.25.12-alpine AS build
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/balance-server ./cmd/balance-server

FROM alpine:3.22
RUN addgroup -S balance && adduser -S -G balance balance && mkdir /data && chown balance:balance /data
USER balance
COPY --from=build /out/balance-server /usr/local/bin/balance-server
ENV BALANCE_ADDR=:8080 BALANCE_DB_PATH=/data/balance.db
EXPOSE 8080
VOLUME ["/data"]
ENTRYPOINT ["balance-server"]
