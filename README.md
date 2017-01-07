# olixshmodule-debian
Module for oliXsh : Installation and configuration of Debian Server


### Initialisation du module

**Pré-requis** :

Initialiser le module qui va récuperer les fichiers de configuration nécessaires à l'installation du server

Command : `olixsh debian init <user>@<host>:/<path> <destination> --port=22`

Entrer les informations suivantes si non saisies en paramètre :

- Le serveur distant de dépôt de la configuration (*user@host:/path*)
- Le port de ce même serveur
- L'emplacement sur le serveur local où seront stockés les fichiers de configuration (*/root*)
- L'emplacement du fichier de configuration (*/path/file.yml*)



### Installation et configuration des packages du serveur

Command : `olixsh debian install <packages...> [--all]`

- `packages` : Liste des packages à installer
- `--all` : Pour installer tous les packages



### Configuration des packages du serveur

Command : `olixsh debian config <package>`

- `package` : Nom du package à configurer



### Sauvegarde des fichiers de configuration des packages du serveur

Copie des fichiers de configuration dans */etc* dans le dépôt local

Command : `olixsh debian savecfg <packages...> [--all]`

- `packages` : Liste des packages à sauvegarder
- `--all` : Pour sauvegarder tous les packages



### Synchronisation de la configuration des packages avec un autre serveur

Synchronise le dépôt local du serveur des fichiers de configuration avec un dépôt distant.

Si le module a été initialisé, les paramètres deviennent facultatifs
et les valeurs par défaut sont ceux dans `/etc/olixsh/debian.conf`

**Récupère la configuration depuis un serveur distant**

Command : `olixsh debian synccfg pull [<user>@<host>:/<path>] [<destination>] [--port=22]`

- `user` : Nom de l'utilisateur de connexion au serveur de dépôt
- `host` : Host du serveur de dépôt
- `path` : Chemin où se trouvent les fichiers de configuration sur le serveur distant
- `destination` : Chemin local où seront déposés les fichiers
- `--port=` : Port du serveur de dépôt

Commande avec module initialisé : `olixsh debian synccfg pull`

**Pousse la configuration vers un serveur distant**

Command : `olixsh debian synccfg push [<user>@<host>:/<path>] [--port=22]`

- `user` : Nom de l'utilisateur de connexion au serveur de dépôt
- `host` : Host du serveur de dépôt
- `path` : Chemin où se trouvent les fichiers de configuration sur le serveur distant
- `--port=` : Port du serveur de dépôt

Commande avec module initialisé : `olixsh debian synccfg push`

