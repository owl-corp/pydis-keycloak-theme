ARG KEYCLOAK_VERSION=26.5.7

FROM maven:3.9.11-eclipse-temurin-21 AS keycloak_source_builder
ARG KEYCLOAK_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates libicu-dev patch && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${KEYCLOAK_VERSION} https://github.com/keycloak/keycloak.git /build/keycloak
COPY keycloak-patches/ /build/keycloak-patches/
WORKDIR /build/keycloak
RUN for p in $(ls /build/keycloak-patches/*.patch | sort); do \
        echo "Applying patch: $p"; \
        git apply "$p"; \
    done
RUN ./mvnw -pl quarkus/deployment,quarkus/dist -am -DskipTests clean install && \
    KEYCLOAK_TAR="$(ls quarkus/dist/target/keycloak-*.tar.gz | head -n 1)" && \
    mkdir -p /opt/keycloak && \
    tar -xzf "${KEYCLOAK_TAR}" -C /opt/keycloak --strip-components=1

FROM eclipse-temurin:21-jre-jammy AS keycloak_from_source
COPY --from=keycloak_source_builder /opt/keycloak /opt/keycloak

FROM node:20 AS keycloakify_jar_builder
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    apt-get install -y maven;
RUN npm install -g pnpm
COPY package.json pnpm-lock.yaml /opt/app/
WORKDIR /opt/app
RUN pnpm install
COPY . .
RUN pnpm run build-keycloak-theme

WORKDIR /tmp/provider-build
COPY vendor/keycloak-providers .
RUN mvn clean package -Drevision=release -DskipTests

FROM keycloak_from_source AS builder
WORKDIR /opt/keycloak
# Build custom LDAP disabled provider from the vendor directory
COPY --from=keycloakify_jar_builder /opt/app/dist_keycloak/keycloak-theme-for-kc-all-other-versions.jar /opt/keycloak/providers/
COPY --from=keycloakify_jar_builder /tmp/provider-build/ldap-disabled-mapper/target/ldap-disabled-mapper-release.jar /opt/keycloak/providers/
ENV KC_DB=postgres
RUN /opt/keycloak/bin/kc.sh build --features="passkeys,scripts"

FROM keycloak_from_source
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]
