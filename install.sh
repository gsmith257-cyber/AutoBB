#!/bin/bash
#install owasp amass
wget https://github.com/OWASP/Amass/releases/download/v3.21.2/amass_linux_amd64.zip
unzip amass_linux_amd64.zip
rm amass_linux_amd64.zip
cd amass_linux_amd64
chmod +x amass
mv amass /usr/local/bin
cd ..
#install JSFScan.sh
git clone https://github.com/KathanP19/JSFScan.sh.git
cd JSFScan.sh
chmod +x install.sh
./install.sh
add=$(pwd)
cd ..
#install hakrawler
go install github.com/hakluke/hakrawler@latest
#install nikto
apt-get install nikto
#install http probe
go install github.com/tomnomnom/httprobe@latest
#install xsstrike
git clone https://github.com/s0md3v/XSStrike.git
cd XSStrike
pip3 install -r requirements.txt
echo "export PATH=$PATH:$(pwd):$add" >> ~/.bashrc
cd ..
#install nuclei
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
#install SSRFire
git clone https://github.com/ksharinarayanan/SSRFire.git
cd SSRFire
chmod +x setup.sh
./setup.sh
cd ..
