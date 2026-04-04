ARG KEYCLOAK_VERSION=26.5.4
ARG KEYCLOAK_GIT_REPO=https://github.com/owl-corp/keycloak.git
ARG KEYCLOAK_BASELINE_REF=release/26.5
ARG KEYCLOAK_PATCH_REF=origin/main

FROM maven:3.9.11-eclipse-temurin-21 AS keycloak_source_builder
ARG KEYCLOAK_GIT_REPO
ARG KEYCLOAK_BASELINE_REF
ARG KEYCLOAK_PATCH_REF

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates libicu-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build/keycloak
RUN git clone "${KEYCLOAK_GIT_REPO}" /build/keycloak && \
        git fetch --all --tags && \
        PATCH_COMMIT="$(git rev-parse "${KEYCLOAK_PATCH_REF}")" && \
        git checkout "${KEYCLOAK_BASELINE_REF}" && \
        BASELINE_COMMIT="$(git rev-parse HEAD)" && \
        if [ "${PATCH_COMMIT}" != "${BASELINE_COMMIT}" ]; then \
            git cherry-pick --no-edit "${PATCH_COMMIT}"; \
        fi
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
