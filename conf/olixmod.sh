###
# Fichier obligatoire contenant la configuration et l'initialisation du module
# ==============================================================================
# @package olixsh
# @module debian
# @label Installation et configuration des packages Debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Paramètres du modules
##
# Version en cours Debian
OLIX_MODULE_DEBIAN_VERSION=$(lsb_release -rs)
OLIX_MODULE_DEBIAN_VERSION_RELEASE=$(lsb_release -cs)

# Si on doit utiliser tous les packages
OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE=false

# Liste des packages en fonction de l'action à traiter
OLIX_MODULE_DEBIAN_PACKAGES_INSTALL="network virtualbox vmware users apache php mysql postgres nfs samba ftp postfix collectd logwatch monit snmpd tools"
OLIX_MODULE_DEBIAN_PACKAGES_CONFIG="apache php mysql postgres nfs samba ftp postfix collectd logwatch monit snmpd tools"
OLIX_MODULE_DEBIAN_PACKAGES_SAVECFG="apache php mysql postgres nfs samba ftp postfix collectd logwatch monit snmpd tools"



###
# Chargement des librairies requis
##
olixmodule_debian_require_libraries()
{
    load "modules/debian/lib/*"
    load "utils/yaml.sh"
}


###
# Retourne la liste des modules requis
##
olixmodule_debian_require_module()
{
    echo -e ""
}


###
# Retourne la liste des binaires requis
##
olixmodule_debian_require_binary()
{
    echo -e "lsb_release"
}


###
# Traitement à effectuer au début d'un traitement
##
olixmodule_debian_include_begin()
{
    # Test si ROOT
    info "Test si root"
    System.logged.isRoot || critical "Seulement root peut executer cette action"
}


###
# Traitement à effectuer au début d'un traitement
##
# olixmodule_debian_include_end()
# {
#    echo "FIN"
# }


###
# Sortie de liste pour la completion
##
# olixmodule_postgres_list()
# {
# }
