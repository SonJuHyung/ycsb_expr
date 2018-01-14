#!/bin/bash 

# common 
OP_TYPE=""
HP_TYPE=""
MFRG_TYPE=""
DIR_CUR=$(pwd) 
DIR_DB=${DIR_CUR}/db
DIR_FTRACE=/sys/kernel/debug/tracing

function usage()
{
    echo ""
    echo " usage : # ./parse_ftrace.sh -d redis -h thp -f ftrace_v1" 
    echo "       : # ./parse_ftrace.sh -d mongodb -h thp -f ftrace_v2"
    echo "" 
    exit
}

while getopts d:h:f: opt 
do
    case $opt in
        d) 
            if [ $OPTARG == "redis" ] || [ $OPTARG == "mongodb" ]
            then
                OP_TYPE=$OPTARG
            else
                echo "  error : benchmark type missing"
                usage 
                exit 0
            fi
            ;;
        h)
            HP_TYPE=$OPTARG
            ;;        
        f)
            MFRG_TYPE=$OPTARG
            ;;
        *)
            usage 
            exit 0
            ;;
    esac
done 

if [ $# -eq 0 ]
then 
    usage 
    exit 
fi 

DIR_LOG=${DIR_DB}/${OP_TYPE}/ftrace/${HP_TYPE}

LOG_INPUT=${DIR_LOG}/ftrace_${OP_TYPE}_${HP_TYPE}_${MFRG_TYPE}.txt
LOG_RESULT=${DIR_LOG}/ftrace_${OP_TYPE}_${HP_TYPE}_${MFRG_TYPE}_result.txt
LOG_RAW=${DIR_LOG}/ftrace_${OP_TYPE}_${HP_TYPE}_${MFRG_TYPE}_raw.txt
TOTAL=0
rm -rf ${LOG_RESULT} ${LOG_RAW}
#cat ${LOG_INPUT} | sed -e '1,4d' |  awk '{ split($0,split_1,"us"); split(split_1[1],split_2," "); printf("%s\n",split_2[0]);}' > a.txt 
while read line 
do 

    TEST=$(echo ${line} | sed 's/ + / /' | sed 's/ ! / /' | sed 's/ # / /' | sed '/us/!d' | awk '{ split($0,split_1,"us"); split(split_1[1],split_2,")"); printf("%s",split_2[2]); }') 
     
    [ -z "$TEST" ] && continue 

    echo ${TEST} >> ${LOG_RAW}

done < ${LOG_INPUT}
#cat a.txt | awk '{ n=split($0,arr,")"); printf("%s\n",arr[2]);}' | sed "s/ + /   /g" > ${LOG_RAW}
#cat ${LOG_RAW} | awk 'BEGIN {sum=0} {for(i=1; i<=NF; i++) sum+=$i } END {print sum}' >> ${LOG_RESULT}

#rm -rf a.txt
#cat b.txt | awk '{ n=split($0,arr," "); for(i=1; i < n; i++) printf("%s\n",arr[1]);}' 
#echo ${ARRAY}



