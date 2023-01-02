#!/bin/bash
#check for two arguments
if [ $# -ne 1 ]
then
    echo "Usage: ./run.sh <target> optional:<cookie>"
    exit
fi
#Get target/cookie from user agument
target=$1
#check if target folder already exsists
if [ -d $target ]
then
    echo "Target folder already exsists, Do you want to overwrite it? (y/n): "
    #check their response
    read response
    if [ $response == "y" ]
    then
        #remove the folder
        rm -rf $target
    else
        #check to see if $target-alive.txt exists
        if [ -f $target/$target-alive.txt ]
        then
            #ask if they want to skip enumeration
            echo "Do you want to skip enumeration? (y/n): "
            read response
            if [ $response == "y" ]
            then
                #Remove everything except $target-alive.txt and $target-subs.txt
                cd $target
                mv $target-alive.txt bak-$target-alive
                mv $target-subs.txt bak-$target-subs
                rm -rf $target*
                mv bak-$target-alive $target-alive.txt
                mv bak-$target-subs $target-subs.txt
                echo "Running nikto on target-alive.txt"
                nikto -o $target-nikto.txt -h $target-alive.txt > /dev/null 2>&1
                
                cd ../XSStrike/
                #if cookie is provided, use itXSStrike
                echo "Running XSStrike on target-alive.txt"
                if [ $# -eq 2 ]
                    then
                        #Run XSStrike on target-alive.txt
                        #save filename as target-XSStrike.txt
                        python3 xsstrike.py --skip-dom --headers $2 --seeds ../$target/$target-alive.txt >> ../$target/$target-XSStrike.txt
                    else
                        #Run XSStrike on target-alive.txt
                        #save filename as target-XSStrike.txt
                        python3 xsstrike.py --skip-dom --seeds ../$target/$target-alive.txt >> ../$target/$target-XSStrike.txt
                fi
                cd ../$target/
                #run nuclei on target-alive.txt
                #save filename as target-nuclei.txt
                echo "Running nuclei on target-alive.txt"
                nuclei -list $target-alive.txt -fhr > $target-nuclei.txt
                #start ngrok in the background, but save output to target-SSRF-ngrok.txt
                echo "Starting ngrok in the background"
                ngrok http 80 > $target-SSRF-ngrok.txt &
                #get url from ngrok output
                url=$(cat $target-SSRF-ngrok.txt | grep "https://[0-9a-z]*\.ngrok.io" -o)
                #Run SSRFire on target-alive.txt
                #save filename as target-SSRFire.txt
                echo "Running SSRFire on target-alive.txt"
                cd ../SSRFire
                cat ../$target/$target-alive.txt | xargs -n1 -P10 ./ssrfire.sh -s $url -f ../$target/$target-alive.txt -d >> ../$target/$target-SSRFire.txt
                echo "Done"
                exit
            fi
        fi
        #exit
        exit
    fi
fi
#Create a directory for the target
mkdir $target
#Change directory to the target
cd $target
#Run OWASP Amass to collect subdomains
#save filename as target-subs.txt and run quietly
echo "Running OWASP Amass to collect subdomains"
amass enum -d $target -o $target-subs.txt -silent

#Test subdomains for alive status
#save filename as target-alive.txt
echo "Testing subdomains for alive status"
cat $target-subs.txt | httprobe >> $target-alive.txt

#collect js links from target main page
#save filename as jsfile_links.txt
#if cookie is provided, use it
echo "Collecting js links from target main page"
if [ $# -eq 2 ]
then
    cat $target-subs.txt | hakrawler -js -cookie $2 -depth 2 -scope subs -plain >> jsfile_links.txt
else
    cat $target-subs.txt | hakrawler -js -depth 2 -scope subs -plain >> jsfile_links.txt
fi
#Run JSFScan.sh on jsfile_links.txt
#NOTE: If you feel tool is slow just comment out hakrawler line at 23 in JSFScan.sh script , but it might result in little less jsfileslinks.
bash JSFScan.sh -l $target --all -r -o $target-JSFScan
#Run nikto on target-alive.txt and save output to "current subdomain" + -nikto.txt
echo "Running nikto on target-alive.txt"
nikto -o $target-nikto.txt -h $target-alive.txt > /dev/null 2>&1

cd ../XSStrike/
#if cookie is provided, use it
echo "Running XSStrike on target-alive.txt"
if [ $# -eq 2 ]
    then
        #Run XSStrike on target-alive.txt
        #save filename as target-XSStrike.txt
        python3 xsstrike.py --skip-dom --headers $2 --seeds ../$target/$target-alive.txt > ../$target/$target-XSStrike.txt
    else
        #Run XSStrike on target-alive.txt
        #save filename as target-XSStrike.txt
        python3 xsstrike.py --skip-dom --seeds ../$target/$target-alive.txt > ../$target/$target-XSStrike.txt
fi
cd ../$target/

#run nuclei on target-alive.txt
#save filename as target-nuclei.txt
echo "Running nuclei on target-alive.txt"
nuclei -list $target-alive.txt -fhr -s critical,high,medium > $target-nuclei.txt
#start ngrok in the background, but save output to target-SSRF-ngrok.txt
echo "Starting ngrok in the background"
ngrok http 80 > $target-SSRF-ngrok.txt &
#get url from ngrok output
url=$(cat $target-SSRF-ngrok.txt | grep "https://[0-9a-z]*\.ngrok.io" -o)
#Run SSRFire on target-alive.txt
#save filename as target-SSRFire.txt
echo "Running SSRFire on target-alive.txt"
cd ../SSRFire
cat ../$target/$target-alive.txt | xargs -n1 -P10 ./ssrfire.sh -s $url -f ../$target/$target-alive.txt -d >> ../$target/$target-SSRFire.txt
echo "Done"
