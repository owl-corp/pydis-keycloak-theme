FROM node:20 as keycloakify_jar_builder
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    apt-get install -y maven;
COPY ./keycloakify-starter/package.json ./keycloakify-starter/pnpm-lock.yaml /opt/app/
WORKDIR /opt/app
RUN pnpm install
COPY ./keycloakify-starter/ /opt/app/
RUN pnpm run build

ARG KEYCLOAK_VERSION=25.0.4
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} as builder
WORKDIR /opt/keycloak
COPY --from=keycloakify_jar_builder /opt/app/dist_keycloak/keycloak-theme-for-kc-22-and-above.jar /opt/keycloak/providers/
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]
