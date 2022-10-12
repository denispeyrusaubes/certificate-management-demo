# Build on Linux
#docker built -t retengr/retengr/initcertificates:0.0.2 .
#docker push retengr/retengr/initcertificates:0.0.2

# Building on Apple M1 
echo "Building initCertificatesfrom Apple M1"
docker buildx build --push --tag retengr/initcertificates:0.0.2 --platform=linux/arm64,linux/amd64 .
