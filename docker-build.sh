#!bin/bash
docker build -t solidfire-ps-powershell-build1 .
docker run -it -v $(pwd)/scripts:/scripts --rm solidfire-ps-powershell-build1 bash
