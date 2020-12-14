#!/bin/bash
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
if [ "$1" == "" ]
then
        echo "Usage --> bash resolver <url>"
else
        wget -q -O $1.resolver $1 > /dev/null
        grep http $1.resolver | cut -d "/" -f 3 | cut -d '"' -f 1 | cut -d ":" -f1 | sort -u > hosts.$1
        echo -e "${GREEN}###############################\n# Hosts encontrados na pagina #\n###############################${WHITE}\n"
        cat hosts.$1
        echo -e "\n${PURPLE}###################################\n# Resoluçao dos hosts encontrados #\n###################################${WHITE}\n"
        for url in  $(cat hosts.$1);
        do
                host $url| sed 's/has address/-->/g' | sed 's/is handled by/-->/g' | sed 's/has IPv6 address/-->/g'| sed 's/domain name pointer/-->/g';
        done
fi