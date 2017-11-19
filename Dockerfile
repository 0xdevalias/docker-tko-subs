FROM golang:alpine AS build-env
RUN apk add --no-cache git ca-certificates
RUN go get github.com/anshumanbh/tko-subs
WORKDIR /go/src/github.com/anshumanbh/tko-subs
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o tko-subs

# TODO: I think we may need to static compile dig ourselves, copying the binary from bind-tools doesn't seem to work..
#   eg. https://github.com/sequenceiq/docker-alpine-dig/blob/master/Dockerfile
# For compiling
#   https://github.com/0xdevalias/docker-tiny-scratch-tools/blob/master/Dockerfile#L2
FROM alpine:edge AS pack-env
WORKDIR /
RUN apk add --no-cache upx bind-tools
COPY --from=build-env /go/src/github.com/anshumanbh/tko-subs/tko-subs /
RUN upx --best --ultra-brute tko-subs -otko-subs.upx
# RUN upx --best --ultra-brute /usr/bin/dig -odig.upx

FROM scratch
# Install ca root certificates
#   https://medium.com/on-docker/use-multi-stage-builds-to-inject-ca-certs-ad1e8f01de1b
COPY --from=build-env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build-env /go/src/github.com/anshumanbh/tko-subs/providers-data.csv /
COPY --from=build-env /go/src/github.com/anshumanbh/tko-subs/domains.txt /
COPY --from=pack-env /usr/bin/dig /usr/bin/dig
COPY --from=pack-env /tko-subs.upx /tko-subs
# ENTRYPOINT ["/tko-subs"]
# TODO: Trying to run dig
#standard_init_linux.go:187: exec user process caused "no such file or directory"
