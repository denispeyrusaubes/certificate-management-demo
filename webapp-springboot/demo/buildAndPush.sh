mvn package

# Build on Linux
#docker built -t retengr/demo-springbot:0.0.1 .
#docker push retengr/demo-springbot:0.0.1

# Building on Apple M1 
echo "Building from Apple M1"
docker buildx build --push --tag retengr/demo-springboot:0.0.1 --platform=linux/arm64,linux/amd64 .
