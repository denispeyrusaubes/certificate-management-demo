FROM ubuntu
run apt update
run apt install openssl
copy createPkcs12.sh /
run chmod +x createPkcs12.sh
WORKDIR /
ENTRYPOINT ["/bin/bash", "/createPkcs12.sh"]