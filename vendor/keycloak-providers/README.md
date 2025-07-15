# keycloak-providers

Build with `mvn clean package`. Copy resulting JARs into Keycloak build.

### disabled-ldap-status-mapper

- Create add a `user-attribute-ldap-mapper` that maps `nsAccountLock` from LDAP to the user attribute `nsAccountLock`.
This is necessary for the next step because the attribute is not fetched unless explicitly requested.
- Add `disabled-ldap-status-mapper` to automatically (un)lock users according to their `nsAccountLock` status in LDAP. 
