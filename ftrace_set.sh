#!/bin/bash 

# common 
OP_TYPE=""
HP_TYPE=""
MFRG_TYPE=""
DIR_CUR=$(pwd) 
DIR_DB=${DIR_CUR}/db
DIR_FTRACE=/sys/kernel/debug/tracing

PID=$(pgrep redis-server)

function usage()
{
    echo ""
    echo " usage : # ./ftrace_set.sh -d redis -h thp -f ftrace_v1" 
    echo "       : # ./ftrace_set.sh -d mongodb -h thp -f ftrace_v2"
    echo "" 
    exit
}

function clearing(){
    echo ""     
    echo " clearing ftrace ..."
    echo nop > ${DIR_FTRACE}/current_tracer 
    echo > ${DIR_FTRACE}/set_ftrace_filter 
    echo > ${DIR_FTRACE}/set_ftrace_pid
    echo > ${DIR_FTRACE}/trace 
    echo " done"
}

trap 'clearing' 2


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

# clearing ftrace 
echo " clearing ftrace ..."
echo nop > ${DIR_FTRACE}/current_tracer 
echo > ${DIR_FTRACE}/set_ftrace_filter 
echo > ${DIR_FTRACE}/set_ftrace_pid
echo > ${DIR_FTRACE}/trace 
echo " done"
# setting ftrace 
echo " redis's pid is ${PID}" 
echo " setting ftrace"
echo ${PID} > ${DIR_FTRACE}/set_ftrace_pid
echo __alloc_pages_nodemask > ${DIR_FTRACE}/set_ftrace_filter 
echo function_graph > ${DIR_FTRACE}/current_tracer 
echo " done"
# redirecting 
#cat ${DIR_FTRACE}/trace_pipe  
echo " redirecting..."
cat ${DIR_FTRACE}/trace_pipe >> ${DIR_DB}/${OP_TYPE}/ftrace/${HP_TYPE}/ftrace_${OP_TYPE}_${HP_TYPE}_${MFRG_TYPE}.txt

