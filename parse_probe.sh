#!/bin/bash 

DB=""
HP_TYPE=""
VERSION=0
DEBUG=0

usage(){
    echo ""    
    echo "  usage : # ./parse_probe.sh -h thp -d redis -v 1" 
    echo "          # ./parse_probe.sh -h nhp -d mongo -v 2 -g" 
    echo ''
} 

if [ $# -eq 0 ]
then 
    usage 
    exit
fi

while getopts d:h:v:g opt
do
    case $opt in 
        h)
            if [ $OPTARG == "nhp" ] || [ $OPTARG == "thp" ]
            then
                HP_TYPE=$OPTARG
            else  
                echo "  error : page type must be thp or nhp" 
                usage 
                exit 0
            fi           
            ;;
        d)
            if [ $OPTARG == "redis" ] || [ $OPTARG == "mongodb" ]
            then
                DB=$OPTARG
            else  
                echo "  error : db must be redis of mongodb" 
                usage 
                exit 0
            fi           
            ;;
        g)
            DEBUG=1
            ;;
        v)
            VERSION=$OPTARG
            ;;
    esac
done

DIR_CUR=$(pwd) 
PROBE_DIR=${DIR_CUR}/db/${DB}/kprobe/${HP_TYPE}
PROBE_FILE=${PROBE_DIR}/probe_${DB}_${HP_TYPE}_${VERSION}.txt 
PROBE_CONTEXT=${PROBE_FILE}  

PREV_ADDR=0
VM_DIFFERENCE=0 
ADDR_DIFFERENCE=0
PAGE_SIZE=0x1000
HPAGE_SIZE=0x200000

ABOVE_HPAGE=0
IN_HPAGE=0
IN_PAGE=0
COUNT=0

while read line 
do     
    PID=$(echo ${line}      | awk '{ split($0,parse_1,","); split(parse_1[1],parse_2,"pid: "); printf("0x%s",parse_2[2]);}') 
    VM_START=$(echo ${line} | awk '{ split($0,parse_1,","); split(parse_1[2],parse_2,": "); printf("0x%s",parse_2[2]);}') 
    VM_END=$(echo ${line}   | awk '{ split($0,parse_1,","); split(parse_1[3],parse_2,": "); printf("0x%s",parse_2[2]);}') 
    ADDRESS=$(echo ${line}  | awk '{ split($0,parse_1,","); split(parse_1[4],parse_2,": "); printf("0x%s",parse_2[2]);}') 
    
    # calculate difference
    if [ "${PREV_ADDR}" != 0 ] 
    then 
       VM_DIFFERENCE=$(echo ${VM_START} ${VM_END} | awk '{ difference=strtonum($2)-strtonum($1); printf("0x%x",difference)};')
       ADDR_DIFFERENCE=$(echo ${PREV_ADDR} ${ADDRESS} | awk '{ difference=strtonum($2)-strtonum($1); if (difference<0){difference=difference*(-1);} printf("0x%x",difference); }') 

       ABOVE_HPAGE=$(echo ${ADDR_DIFFERENCE} ${HPAGE_SIZE} ${ABOVE_HPAGE} | awk '{ diff=strtonum($1); hpage_size=strtonum($2); count=strtonum($3); if (diff >= hpage_size) { count+=1;} printf("%d",count); }') 
       IN_HPAGE=$(echo ${ADDR_DIFFERENCE} ${PAGE_SIZE} ${HPAGE_SIZE} ${IN_PAGE} | awk '{ diff=strtonum($1); page_size=strtonum($2); hpage_size=strtonum($3); count=strtonum($4);if (diff >= page_size && diff < hpage_size){ count+=1;} printf("%d",count); }')  
       IN_PAGE=$(echo ${ADDR_DIFFERENCE} ${PAGE_SIZE} ${IN_PAGE} | awk '{ diff=strtonum($1); page_size=strtonum($2); count=strtonum($3);if (diff < page_size){ count+=1;} printf("%d",count); }') 
       COUNT=`expr $COUNT + 1`
    fi
       
    # print out
    if [ "${DEBUG}" != 0 ]
    then
#        echo pid: ${PID}, vm_start: ${VM_START}, vm_end: ${VM_END}, addr: ${ADDRESS}, vma_size: ${VM_DIFFERENCE}, addr_diff: ${ADDR_DIFFERENCE}
        echo prev_addr: ${PREV_ADDR}, addr: ${ADDRESS}, addr_diff: ${ADDR_DIFFERENCE}, out_hpage: ${ABOVE_HPAGE}, in_hpage: ${IN_HPAGE}, in_page: ${IN_PAGE}, ${COUNT}

    else 
        echo ${PID}, ${VM_START}, ${VM_END}, ${ADDRESS} ${VM_DIFFERENCE}, ${ADDR_DIFFERENCE}, ${ABOVE_HPAGE}, ${IN_HPAGE}, ${IN_PAGE}, ${COUNT}
    fi

    PREV_ADDR=${ADDRESS} 
done < ${PROBE_CONTEXT}

#echo ${ABOVE_HPAGE}, ${IN_HPAGE}, ${IN_PAGE}, ${COUNT}


