docker build -t solidfire-ps-powershell -f dockerfile-ps-build .
docker run -it -v $(pwd):/scripts --rm solidfire-ps-powershell bash
