echo "Converting certificate into pkcs12"

openssl pkcs12 -des3 -name myAlias -export -out /pkcs12/server.p12 -inkey /app/cert/www.rtg-demo-opt.com-key.key  -in /app/cert/ww
w.rtg-demo-opt.com-server.crt -password pass:denis -des3