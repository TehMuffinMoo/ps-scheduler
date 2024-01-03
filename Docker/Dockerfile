# escape=`

# From Microsoft's official Centos-7 image
FROM mcr.microsoft.com/powershell:centos-7

# Obligatory update
RUN yum update -y

# Required for gssntlmssp
RUN yum install -y epel-release

# Update now that we have epel-release
RUN yum update -y

# Install libraries for NTLM support
RUN yum install -y gssntlmssp

# Add Scheduler Script
ADD ./Docker/scheduler.ps1 /ps-scheduler/scheduler.ps1

# Set Shell to Powershell
ENTRYPOINT ["/usr/bin/pwsh","-File","/ps-scheduler/scheduler.ps1"]
