# Constat :

Une gestion « à la main » des certificats qui sont nécessaires aux PODs a été mise en place.
De ce que j’ai compris, les certificats et clés privés sont embarqués dans les POD qui en ont besoin.

# Ressources

Le code de cette démo est sur mon répo : 
[https://github.com/denispeyrusaubes/certificate-management-demo](https://github.com/denispeyrusaubes/certificate-management-demo)

# Environnement de test

Cette démo a été déployée sur un cluster K9S déployé sur AWS (EKS).

# Objectifs

Présenter une solution qui met l’accent sur les points suivants

- La gestion des informations de sécurité (certificat, clés privées) sont à la charge des OPS. Les développeurs de sont pas supposés y accéder. Ils seront donc stockés dans un secret appelé `certs-secret-www.rtg-demo-opt.com`
- Les pods qui auront besoin du certificat et de la clé privée utiliseront donc ce secret.

# Présentation de la démo :

## Arborescence de la démo

La démo se décompose en 3 charts helms :

* `ops-certificate-management`

    Contient les éléments à déployer par les ops :
    - La clé privée
    - le certificat autosigné

    Ces deux informations seront regroupées dans un `secret`Kubernetes appelé `certs-secret-www.rtg-demo-opt.com`.

    le répertoire `certs-artifacts` contient les éléments de sécurité nécessaires à la mise en place du POC, et plus précisemment des ressources `ops-certificate-management` (Le certificat auto signé et la clé privée)

    Le certificat autosigné et la clé privée ont été générés de la façon suivante, et protège l'accès à un site web dont l'url est `www.rtg-demo-opt.com`.

    ```
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout  server.key -out ca.crt -subj "/C=NC/C=NC/CN=www.rtg-demo-opt.com" 
    ```

    > Aucune passphrase n'a été positionnée par mesure de simplification. Ce n'est pas une bonne pratique, mais cela permet de simplifier un peu  la démonstration

* `webapp-nginx`

    Un exemple d'utilisation des éléments précédent dans le cas d'un pod qui héberge un serveur web `nginx` standard.
    Nous aurions pu prendre un serveur web `Apache`, cela n'aurait pas modifié grand chose à la démonstration.


* `webapp-springboot`

    Un exemple d'utilisation des éléments précédent dans le cas d'un pod qui héberge ue application Springboot (java)
    Le projet Springboot utilisé par la démo est dans `./webapp-springboot/demo` (java 17)
    Le code de l'`initContainer` décrit ci-dessous est dans `./webapp-springboot/initcontainer`

    :exclamation: cette démonstration ne fonctionne pas avec une application Springboot utilisant le JDK 1.8 (non support du chiffrement AES). 


# Rôle des OPS :

Les OPS se contentent de déployer le chart contenu dans `ops-certificate-management` :

```
helm install security-management ./ops-certificate-management
```

Ce chart contient une seule ressource de type secret `certs-secret-www.rtg-demo-opt.com`:

```
$ kubectl describe secrets/certs-secret-www.rtg-demo-opt.com
Name:         certs-secret-www.rtg-demo-opt.com
Namespace:    default
Labels:       app.kubernetes.io/managed-by=Helm
Annotations:  meta.helm.sh/release-name: security-management
              meta.helm.sh/release-namespace: default

Type:  Opaque

Data
====
www.rtg-demo-opt.com-cert:        1078 bytes
www.rtg-demo-opt.com-server-key:  1704 bytes

```

Il contient le certificat et la clé privée.

J'ai procédé de la façon suivante pour générer le fichier du secret :
``` 
# cd certs-artifacts

# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout  server.key -out ca.crt -subj "/C=NC/C=NC/CN=www.rtg-demo-opt.com" 

# kubectl create secret generic my-secret --from-file=www.rtg-demo-opt.com-cert=ca.crt --from-file=www.rtg-demo-opt.com-server-key=server.key -o yaml > ../templates/certs-secret-www.rtg-demo-opt.com.yml
``` 

:exclamation: **Le rôle des ops est maintenant terminé**

Il est de la responsabilité des devs d’utiliser ce secret pour déployer leur PODs.

Deux cas sont décrits ci-dessous:

- Sécuritation d'un pod contenant simplement NGINX
- Sécuritation d'un pod contenant une application Springboot

# NGINX

Cette démo aurait évidemment pu être faîtes avec Apache, les principes sont identiques.

Pour activer SSL sur un serveur nginx, 3 ressources doivent être modifiées et/ ou ajoutées :
- `/etc/nginx/nginx.conf`
- La clé privée
- Le certificat 

> dans la vrai vie, il faudrait en plus le CACert mais j’utilise un certificat autosigné

Ces ressources ne **doivent pas** être mise en dur dans l’image; Nous optons donc sur l’usage du principe des volumes pour les y ajouter au moment du déploiement.
Le paramétrage du [Pod Nginx](https://github.com/denispeyrusaubes/certificate-management-demo/blob/master/webapp-nginx/templates/nginx-deployment.yml) déclare tous ces volumes :

```
     - name: nginx
        image: nginx
        volumeMounts:
          - name: secret-volume
            mountPath: /app/cert
          - name: config-volume
            mountPath: /etc/nginx/nginx.conf
            subPath: nginx.conf
      volumes:
      - name: secret-volume
        secret:
          secretName: certs-secret-www.rtg-demo-opt.com
          items:
            - key: www.rtg-demo-opt.com-cert
              path: www.rtg-demo-opt.com-server.crt
            - key: www.rtg-demo-opt.com-server-key
              path: www.rtg-demo-opt.com-key.key

      - name: config-volume
        configMap:
          name: nginx-ssl-conf
          items:
            - key: nginx.conf
              path: nginx.conf
```



-  `/app/cert` : nom choisi par mes soins. Je monte le secret `certs-secret-www.rtg-demo-opt.com` sur ce répertoire. Les valeurs déclarées dans ce fichiers deviennent maintenant accessible comme fichier dans le pod.
- `/etc/nginx/nginx.conf` : il est possible de substituer le fichier en standard dans l’image à l’aide d’un `ConfigMap` créé précédemment :[nginx-ssl-conf-configmap.yml](https://github.com/denispeyrusaubes/certificate-management-demo/blob/master/webapp-nginx/templates/nginx-ssl-conf-configmap.yml). Ce fichier fait le paramétrage SSL en faidant référence à la clé privée et au certificat maintenant accessible dans `/app/cert`. Ce fichier pourra évidemment être adapté à votre contexte pour paramétrer votre application web.

Déploiement de l'application nginx :

```
helm install mynginx ./webapp-nginx
```

le serveur nginx démarre maintenant en utilisant le certificat qui a été mis à disposition :

Afin de tester que le certificat est bien installé :

```
$ kubectl port-forward service/demo-security 8443:443
$ echo | openssl s_client -showcerts -servername localhost -connect localhost:8443 2>/dev/null | openssl x509 -inform pem -noout -text
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 14467228418487886182 (0xc8c5eb9890682166)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=NC, C=NC, CN=www.rtg-demo-opt.com
        Validity
            Not Before: Oct 12 04:05:24 2022 GMT
            Not After : Oct 12 04:05:24 2023 GMT
        Subject: C=NC, C=NC, CN=www.rtg-demo-opt.com
        ...
```

:heart_eyes: Le certificat retourné, est bien celui qui a été déclaré dans le secret par les `OPS`.


# Springboot

La mise en place de ssl avec Springboot est un peu plus complexe.

En effet, le certificat et la clé privée doivent-être stockés dans un coffre PKCS12 afin de pouvoir être utilsé par votre application Java.

Une étape de transformation des informations contenues dans le secret `certs-secret-www.rtg-demo-opt.com` ne sont pas au bon format.

:exclamation: La JVM sait manipuler des coffres sécurisés dans un format `pksc12`. Nous allons donc devoir générer ce fichier à partir du secret qui contient le certificat et la clé privé.

Pour cela, j'ai utilisé un `initContainer` qui permettra de faire cette transformation et de mettre le fichier `secret.p12` à disposition de l'application Springboot. 

La déclaration de cet `initContainer` est visible [ici](https://github.com/denispeyrusaubes/certificate-management-demo/blob/master/webapp-springboot/templates/deployment.yaml). On notera que l'`initContainer` monte le secret `certs-secret-www.rtg-demo-opt.com` via un volume afin de pouvoir transformer les information contenues en PKCS12. La commande utilisée par l'`initcontainer` est :

```
openssl pkcs12 -name myAlias -export -out /pkcs12/server.p12 -inkey /app/cert/www.rtg-demo-opt.com-key.key  -in /app/cert/www.rtg-demo-opt.com-server.crt -password pass:denis
```

> Vous noterez le mot de passe "denis" codé en dur...

L'image qui fera office d'`initContainer` est construite par mes soins, elle est visible [ici](https://github.com/denispeyrusaubes/certificate-management-demo/tree/master/webapp-springboot/initcontainer)


:exclamation: Attention, un paramétrage de l'application springboot est nécessaire pour lui dire d'utiliser ssl et qu'il trouve le fichier pkcs12 : [application.properties](https://github.com/denispeyrusaubes/certificate-management-demo/blob/master/webapp-springboot/demo/src/main/resources/application.properties).  

:exclamation: un réflexion devra donc être menée afin que la CI builde une image docker de vos applications springboot en tenant compte de cette spécificité. L'usage de profil d'éxécution dans Springboot permet certainement d'adresser ce problème.

Une fois déployée le chart helm de l'application springboot, nous pouvons tester le certificat :

```
$ helm install springboot ./webapp-springboot

$ testhost=$(kubectl get service/demo-security-springboot --output=jsonpath="{.status.loadBalancer.ingress[0]['hostname']}")
$ echo | openssl s_client -showcerts -servername $testhost -connect $testhost:8443 2>/dev/null | openssl x509 -inform pem -noout -text

Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 14467228418487886182 (0xc8c5eb9890682166)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=NC, C=NC, CN=www.rtg-demo-opt.com
        Validity
            Not Before: Oct 12 04:05:24 2022 GMT
            Not After : Oct 12 04:05:24 2023 GMT
        Subject: C=NC, C=NC, CN=www.rtg-demo-opt.com
```

:heart_eyes: Là encore, le certificat retourné est bien celui qui a été déclaré dans le secret `certs-secret-www.rtg-demo-opt.com` par les `OPS`.

# Conclusion

`certs-secret-www.rtg-demo-opt.com` est un endroit unique de déclaration du certificat et de la clé privée.

Nous sommes parvenu à exploiter ce secret depuis un pod hébergeant `nginx` et un autre utilisant `Springboot`.

C'était bien l'objet de cette démo.

# Remarque d'autre général sur cette démo

Même si elle rempli ces objectifs initiaux, elle reste imparfaite :
- J'utilise un certificat autosigné (quelques modifications permettront d'utiliser les certificats de l'opt)
- pas de passphrase
- le mot de passe du coffre pkcs est en dur dans mon code ("denis")
- Je n'ai pas fais le lien avec les ingress éventuels qui seront positionnés en amont des pods et services. 

Contrairement au secret, La modification du configmap n'est pas propagée au pods qui l'utilise. les nouvelles informations seront prises en compte au redémarrage du pod.

:exclamation: un secret ne chiffre pas les informations qu'il contient par défaut (ils sont juste encodés en `base64`). Une reflexion plus globale devra être menée sur ce sujet notamment le chiffrement des secret avec un KMS extérieur (exemple [hashicorp vault](https://www.hashicorp.com/resources/vault-and-kubernetes-better-together))