docker build -t solidfire-ps-powershell-demo1 -f dockerfile-ps-build-demo1 .
docker run -it -v $(pwd):/scripts --rm solidfire-ps-powershell-demo1 bash
