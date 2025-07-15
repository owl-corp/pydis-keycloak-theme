package uk.owlcorp.keycloak;

import org.jboss.logging.Logger;
import org.keycloak.component.ComponentModel;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.storage.ldap.LDAPStorageProvider;
import org.keycloak.storage.ldap.idm.model.LDAPObject;
import org.keycloak.storage.ldap.idm.query.internal.LDAPQuery;
import org.keycloak.storage.ldap.mappers.AbstractLDAPStorageMapper;

public class DisabledStatusLDAPStorageMapper extends AbstractLDAPStorageMapper {

    private final Logger log = Logger.getLogger(DisabledStatusLDAPStorageMapper.class);
    private static final String LDAP_LOCKED_ATTR = "nsAccountLock";

    public DisabledStatusLDAPStorageMapper(ComponentModel mapperModel, LDAPStorageProvider ldapProvider) {
        super(mapperModel, ldapProvider);
    }

    @Override
    public void onImportUserFromLDAP(
            LDAPObject ldapObject, UserModel userModel, RealmModel realmModel, boolean isCreate) {
        log.debugf("LDAP user attributes: %s", ldapObject.getAttributes());
        boolean accLocked = "TRUE".equals(ldapObject.getAttributeAsString(LDAP_LOCKED_ATTR));
        if (!isCreate && userModel.isEnabled() && accLocked) {
            log.infof("Disabling user [%s] in realm [%s] because their federated LDAP account got locked.",
                    userModel.getUsername(), realmModel.getName());
        }
        if (!isCreate && !userModel.isEnabled() && !accLocked) {
            log.infof("Enabling user [%s] in realm [%s] because their federated LDAP account got un-locked.",
                    userModel.getUsername(), realmModel.getName());
        }
        userModel.setEnabled(!accLocked);
    }

    // This method is untested and unused unless we enable KC -> LDAP synchronisation in the future
    @Override
    public void onRegisterUserToLDAP(LDAPObject ldapObject, UserModel userModel, RealmModel realmModel) {
        throw new RuntimeException("KC -> LUMS Sync currently unsupported");
    }

    @Override
    public UserModel proxy(LDAPObject ldapObject, UserModel userModel, RealmModel realmModel) {
        onImportUserFromLDAP(ldapObject, userModel, realmModel, false);
        return userModel;
    }

    @Override
    public void beforeLDAPQuery(LDAPQuery ldapQuery) {
    }

}
