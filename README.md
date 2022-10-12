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

Remarque : les commandes suivantes sont déja exécutées et leur résultat son en conf (ce n'est évidemment pas une bonne pratique, mais c'est pour la démo !)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout  server.key -out ca.crt -subj "/C=NC/C=NC/CN=www.rtg-demo-opt.com" 

# Vérification

kubectl port-forward service/demo-security 8443:443

echo | openssl s_client -showcerts -servername localhost -connect localhost:8443 2>/dev/null | openssl x509 -inform pem -noout -text



## Création des ressources

```
helm install security-management ./ops-certificate-management
helm install demo-app-nginx ./webapp-nginx
```