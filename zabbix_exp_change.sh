#!/bin/bash

SCRIPT_NAME="zabbix_exp_change"

### MySQL
  MY_USER=mysql
  MY_PASS=hogehoge

##################################################


#-------------------------------------------------
err_handling(){
        if [ $? -ne 0 ];then
                ${LOGGER} "<ERROR>   ${MESSAGE}"
                exit 1
        fi
                ${LOGGER} "<SUCCESS> ${MESSAGE}"
}
#-------------------------------------------------

LOGGER="logger -t ${SCRIPT_NAME}"

if [ $# -ne 2 ] ; then
      MESSAGE="Argument is not enough. [ FLAG : 1 or 2 ] [exp.conf]"
      ${LOGGER} "<ERROR>   ${MESSAGE}"
    exit 1
fi

FLAG="$1"
EXP_LIST="$2"

if [ ! -f "${EXP_LIST}" ] ; then
      MESSAGE="[${EXP_LIST}] cannot access."
      ${LOGGER} "<ERROR>   ${MESSAGE}"
    exit 1
fi

#----------

i=0

while read line
do
  if [ "${line}" != "" ] && [ "${line:0:1}" != "#" ] ; then
      EXP_STRING[${i}]=${line}
      i=$((i+1))
  fi
done < ${EXP_LIST}


if [ ${i} != 5 ] ; then
      MESSAGE="EXP_STRING is abnormality."
      ${LOGGER} "<ERROR>   ${MESSAGE}"
    exit 1
fi


case "$FLAG" in 
  "1") # ADD
      MESSAGE="GET EXP_ID"
      SQL="select expressionid from expressions order by expressionid DESC limit 1;"
      EXP_ID=`echo "${SQL}" | mysql -u${MY_USER} -p${MY_PASS} zabbix -N  2>>/var/log/messages`
      err_handling
      EXP_ID=$((EXP_ID + 1))


      MESSAGE="INSERT EXP_LANG"
      SQL=" \
          INSERT INTO expressions \
            (expressionid, regexpid, expression, expression_type, exp_delimiter, case_sensitive) \
             VALUES \
            (${EXP_ID}, ${EXP_STRING[0]}, '${EXP_STRING[1]}', ${EXP_STRING[2]}, '${EXP_STRING[3]}', ${EXP_STRING[4]}) ;"

      echo "${SQL}" | mysql -u${MY_USER} -p${MY_PASS} zabbix -N  >> /var/log/messages  2>&1
      err_handling
      ;;

  "2") # ERASE
      MESSAGE="DELETE EXP_LANG"
      SQL=" \
          DELETE FROM expressions \
          WHERE \
            regexpid = ${EXP_STRING[0]} \
             and
            expression = '${EXP_STRING[1]}' ;"

      echo "${SQL}" | mysql -u${MY_USER} -p${MY_PASS} zabbix -N  >> /var/log/messages  2>&1
      err_handling
      ;;

  *)
      MESSAGE="FLAG[$1] not supported."
      ${LOGGER} "<ERROR>   ${MESSAGE}"
      ;;
  esac

exit 0



