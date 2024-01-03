# escape=`

FROM ubuntu:latest

# Update the list of packages
RUN apt-get update

# Install pre-requisite packages.
RUN apt-get install -y wget apt-transport-https software-properties-common

# Download the Microsoft repository keys
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb

# Register the Microsoft repository keys
RUN dpkg -i packages-microsoft-prod.deb

# Delete the Microsoft repository keys file
RUN rm packages-microsoft-prod.deb

# Fix TLS Error
ENV GNUTLS_CPUID_OVERRIDE=0x1

# Update the list of packages after we added packages.microsoft.com
RUN apt-get update

# Install PowerShell
RUN apt-get install -y powershell

# Add Scheduler Script
ADD ./Docker/scheduler.ps1 /ps-scheduler/scheduler.ps1

# Set Shell to Powershell
ENTRYPOINT ["pwsh","-File","/ps-scheduler/scheduler.ps1"]
