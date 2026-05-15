FROM swift:6.1-noble AS build

WORKDIR /build

COPY Package.swift ./
RUN swift package resolve

COPY Sources ./Sources

RUN swift build -c release --product AuraBackend

FROM swift:6.1-noble

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update \
    && apt-get -q install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --home-dir /app vapor

WORKDIR /app

COPY --from=build --chown=vapor:vapor /build/.build/release/AuraBackend ./AuraBackend

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./AuraBackend"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]
