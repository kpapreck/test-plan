docker build -t solidfire-ps-powershell-build1 .
docker run -it -v $(pwd):/scripts --rm solidfire-ps-powershell-build1 bash
