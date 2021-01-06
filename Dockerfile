FROM golang:1.15.6 AS builder
WORKDIR /go/src/urlredirect
RUN go get -d -u -v github.com/Azure/azure-sdk-for-go/storage
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
#COPY --from=builder /etc/ssl/certs/* /etc/ssl/certs/
WORKDIR /root/
COPY --from=builder /go/src/urlredirect/app .
EXPOSE 8080
CMD ["./app"]  