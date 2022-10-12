#mvn package

# Build on Linux
#docker build -t retengr/demo-springboot:0.0.2 .
#docker push retengr/demo-springboot:0.0.2

# Building on Apple M1 
echo "Building from Apple M1"
docker buildx build --push --tag retengr/demo-springboot:0.0.1 --platform=linux/arm64,linux/amd64 .
