#!/bin/bash 

# common 
OP_TYPE=""
HP_TYPE=""
MFRG_TYPE=""
DIR_CUR=$(pwd) 
TRACE_DIR=/sys/kernel/debug/tracing
TRACE_PIPE=${TRACE_DIR}/trace_pipe 
DIR_PROBE=${DIR_CUR}/db

trap 'echo " unloading kprove module ..."; rmmo``d son_probe.ko' 2
function usage()
{
    echo ""
    echo " usage : # ./trace_pipe.sh -d redis -h thp -f probe_v1" 
    echo "       : # ./trace_pipe.sh -d mongodb -h thp -f probe_v2"
    echo ""

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



rmmod son_probe.ko
echo ""
echo " clearing trace output ..."
echo > ${TRACE_DIR}/trace  
echo ""
echo " loading kprove module ..."
insmod son_probe.ko 
echo " redirecting trace output ..."
cat ${TRACE_PIPE} >> ${DIR_PROBE}/${OP_TYPE}/kprobe/${HP_TYPE}/probe_${OP_TYPE}_${HP_TYPE}_${MFRG_TYPE}.txt
echo ""
echo " unloading kprove module ..."
rmmod son_probe.ko 
exit

