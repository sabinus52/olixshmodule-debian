###
# Fichier de configuration de la version de la distribution debian en cours
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##

! File.exists "$OLIX_MODULE_PATH/debian/conf/$OLIX_MODULE_DEBIAN_VERSION_RELEASE.sh" && critical "Distribution Debian '$OLIX_MODULE_DEBIAN_VERSION_RELEASE' non disponible"
load "modules/debian/conf/$OLIX_MODULE_DEBIAN_VERSION_RELEASE.sh"
