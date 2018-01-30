FROM ubuntu:14.04
#update and install pre-requisites
RUN apt-get update
RUN apt-get install sudo -y
RUN sudo apt-get install curl -y
RUN sudo apt-get install apt-transport-https -y
RUN sudo apt-get update -y
RUN sudo apt-get install unzip -y

#Download the latest PowerCLI_Core from Vmware to your pwd: https://labs.vmware.com/flings/powercli-core#instructions

#Copy downloaded file into the container 
COPY PowerCLI_Core.zip /

RUN curl -SLO https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.18/powershell_6.0.0-alpha.18-1ubuntu1.14.04.1_amd64.deb
RUN apt-get install libunwind8 libicu52 libcurl3 -y
RUN dpkg -i powershell_6.0.0-alpha.18-1ubuntu1.14.04.1_amd64.deb
RUN apt-get install -f

#install SolidFire 1.4 bits
RUN sudo su
RUN mkdir -p /usr/local/share/powershell/Modules/SolidFire
RUN cd /usr/local/share/powershell/Modules/SolidFire && curl --remote-name-all https://raw.githubusercontent.com/solidfire/sdk-dotnet/master/package/SolidFire.SDK.dll https://raw.githubusercontent.com/solidfire/PowerShell/1.4/packages/Newtonsoft.Json.dll https://raw.githubusercontent.com/solidfire/PowerShell/1.4/packages/SolidFire.dll https://raw.githubusercontent.com/solidfire/PowerShell/1.4/packages/SolidFire.psd1 https://raw.githubusercontent.com/solidfire/PowerShell/1.4/packages/Initialize-SFEnvironment.ps1 https://raw.githubusercontent.com/solidfire/PowerShell/1.4/packages/SolidFire.dll-help.xml >/dev/null && cd -

RUN  echo ". /usr/local/share/powershell/Modules/SolidFire/Initialize-SFEnvironment.ps1" > /opt/microsoft/powershell/6.0.0-alpha.18/profile.ps1

#install PowerCLI Pre-requisites
RUN echo "Get-Module -ListAvailable PowerCLI* | Import-Module" >> /opt/microsoft/powershell/6.0.0-alpha.18/profile.ps1
RUN echo "Set-PowerCLIConfiguration  -InvalidCertificateAction Ignore" >> /opt/microsoft/powershell/6.0.0-alpha.18/profile.ps1
RUN echo "connect-sfcluster -target 10.1.1.100 -user admin -password solidfire" >> /opt/microsoft/powershell/6.0.0-alpha.18/profile.ps1
RUN echo "connect-viserver -server 10.1.1.30 -user administrator@demo1.local -password !1Solidfire" >> /opt/microsoft/powershell/6.0.0-alpha.18/profile.ps1

RUN cp PowerCLI_Core.zip /usr/local/share/powershell/Modules/
WORKDIR /usr/local/share/powershell/Modules
RUN unzip PowerCLI_Core.zip
RUN unzip PowerCLI.ViCore.zip
RUN unzip PowerCLI.Vds.zip

#Bring in Test Plan Scripts
#WORKDIR /
#RUN apt-get install git -y
#RUN mkdir scripts
#RUN cd scripts
#RUN git clone https://github.com/kpapreck/test-plan

