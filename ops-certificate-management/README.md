# Déclaration des ressources dans le chart `ops-certificate-management`

Pour information, les fichiers des ressources présents dans templates ont été générés à l'aide des commandes suivantes. Attention, le `--dry-run` est ignoré, les ressources sont donc réellement créées, il faut les supprimer ensuite ;)

```
# le répertoire resource contient le fichier de conf
kubectl create configmap nginx-ssl-conf --from-file=resources/ -o yaml --dry-run\n

kubectl create secret generic certs-secret \
--from-file=www.rtg-demo-opt.com-cert=../certs-artifacts/ca.crt \
--from-file=www.rtg-demo-opt.com-server-key=../certs-artifacts/server.key --dry-run=client -o yaml
```

# secret

le secret `certs-secret-www.rtg-demo-opt.com.yml` contient les informations nécessaires au paramétrage ssl : 

Dans le cas de la démo, il s'agit d'un certificat auto-signé et de sa clé privée.

ce secret contient le certificat pour répondre à l'url www.rtg-demo-opt.com.yml.

Suivant le même modèle on peut créer autant de secret que l'on a d'url à protéger compta.rtg-demo-opt.com, rh.rtg-demo-opt.com, ou alors avoir mis dans un secret ce qu'il faut pour répondre à *.rtg-demo-opt.com.

# Conclusion

Le secret (et donc le certificat et la clé privée) est prêt pour être utilisé par n'importe quel pod qui en a besoin.
