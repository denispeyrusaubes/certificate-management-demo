# Objectif

Mise en place d'un structure permettant de gérer les certificats OPT dans le cadre de Kubernetes

# Description des éléments

Plusieurs charts sont utilisés :

* `ops-certificate-management`

    Contient les éléments à déployer par les ops :
    - un secret pour la clé privée
    - une confirmap pour le certificat

* `webapp-nginx`

    Un exemple d'utilisation des éléments précédent dans le cas d'un pod qui héberge un nginx

* `webapp-springboot`

    Un exemple d'utilisation des éléments précédent dans le cas d'un pod qui héberge ue application Springboot (java)

* `certs-artifacts`

    contient les éléments de sécurité nécessaires à la mise en place du POC

    - Le certificat auto signé
    - la clé privée


# génération des éléments de sécurité

Remaque : les commandes suivantes sont déja exécutées et leur résultat son en conf (ce n'est évidemment pas une bonne pratique, mais c'est pour la démo !)

- Génération du CA
```
cd certs-artifacts

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ca.key -out ca.crt

Country Name (2 letter code) []:NC
State or Province Name (full name) []:NC
Locality Name (eg, city) []:Noumea
Organization Name (eg, company) []:OPT
Organizational Unit Name (eg, section) []:test
Common Name (eg, fully qualified host name) []:www.rtg-demo-opt.com
Email Address []:denis@retengr.com



- Génération du cértificat SSL
```
# Génération de la clé privée du serveur
# openssl genrsa -out server.key 2048
openssl genrsa  -aes256 -out server.key 4096


# CSR
cat csr.conf
openssl req -new -key server.key -out server.csr -config csr.conf

# Generation du certificat
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -days 10000 \
    -extfile csr.conf
```

# Déclaration des ressources dans le chart `ops-certificate-management`

## Pense bête

Pour information, les fichiers des ressources présents dans ce chart ont été générés à l'aide la commande suivante. Attention, le `--dry-run` est ignoré, les ressources sont donc réellement créées, il faut les supprimer ensuite ;)

```
# le répertoire resource contient le fichier de conf
kubectl create configmap nginx-ssl-conf --from-file=resources/ -o yaml --dry-run\n

kubectl create secret generic certs-secret \
--from-file=www.rtg-demo-opt.com-cert=server.crt \
--from-file=www.rtg-demo-opt.com-server-key=server.key --dry-run=client -o yaml
```

## Création des ressources

```
helm install security-management ./ops-certificate-management