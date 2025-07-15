package uk.owlcorp.keycloak;

import org.keycloak.component.ComponentModel;
import org.keycloak.storage.ldap.LDAPStorageProvider;
import org.keycloak.storage.ldap.mappers.AbstractLDAPStorageMapper;
import org.keycloak.storage.ldap.mappers.AbstractLDAPStorageMapperFactory;


public class DisabledStatusLDAPStorageMapperFactory extends AbstractLDAPStorageMapperFactory {

    private final static String MAPPER_NAME = "disabled-ldap-status-mapper";

    @Override
    protected AbstractLDAPStorageMapper createMapper(ComponentModel componentModel, LDAPStorageProvider ldapStorageProvider) {
        return new DisabledStatusLDAPStorageMapper(componentModel, ldapStorageProvider);
    }

    @Override
    public String getId() {
        return MAPPER_NAME;
    }

    @Override
    public String getHelpText() {
        return "Maps the nsAccountLock LDAP attribute to the enabled status of the associated Keycloak account.";
    }

}
