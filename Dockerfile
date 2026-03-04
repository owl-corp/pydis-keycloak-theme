ARG KEYCLOAK_VERSION=26.5.4
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

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} AS builder
WORKDIR /opt/keycloak
# Build custom LDAP disabled provider from the vendor directory
COPY --from=keycloakify_jar_builder /opt/app/dist_keycloak/keycloak-theme-for-kc-all-other-versions.jar /opt/keycloak/providers/
COPY --from=keycloakify_jar_builder /tmp/provider-build/ldap-disabled-mapper/target/ldap-disabled-mapper-release.jar /opt/keycloak/providers/
ENV KC_DB=postgres
RUN /opt/keycloak/bin/kc.sh build --features="passkeys,scripts"

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]
