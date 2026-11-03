FROM swift:6.4-noble AS build

WORKDIR /build

COPY Package.swift Package.resolved ./
RUN swift package resolve --force-resolved-versions

COPY Sources ./Sources

RUN swift build -c release --product AuraBackend --static-swift-stdlib

# The Swift libraries are linked into the binary, so the small image is enough
FROM swift:6.4-noble-slim

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update \
    && apt-get -q install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --home-dir /app vapor

WORKDIR /app

COPY --from=build --chown=vapor:vapor /build/.build/release/AuraBackend ./AuraBackend
COPY --chown=vapor:vapor Public ./Public

USER vapor:vapor

# Vapor logs only notices in production by default, and token usage and AI failures need more
ENV LOG_LEVEL=info

EXPOSE 8080

ENTRYPOINT ["./AuraBackend"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]
