BASE_LOG_FOLDER='{{ params.base_log_folder }}'
MAX_LOG_AGE_IN_DAYS='{{ dag_run.conf.maxLogAgeInDays if dag_run.conf.maxLogAgeInDays else params.default_max_log_age_in_days }}'
ENABLE_DELETE='{{ params.enable_delete }}'

cleanup()
{
    STATEMENT=$1
    OBJECT_TYPE=$2

    MARKED_FOR_DELETE=$(${STATEMENT})
    MARKED_FOR_DELETE_COUNT=$(echo "${MARKED_FOR_DELETE}" | grep -v '^$' | wc -l)

    if [ "${MARKED_FOR_DELETE_COUNT}" -gt "0" ];
    then
        echo "Script will delete ${MARKED_FOR_DELETE_COUNT} ${OBJECT_TYPE}(s) older than ${MAX_LOG_AGE_IN_DAYS} days from ${BASE_LOG_FOLDER}:"
        echo "${MARKED_FOR_DELETE}"
        echo ""

        if [ "${ENABLE_DELETE}" == "true" ];
        then
            DELETE_STMT="${STATEMENT} -delete"
            echo "Executing delete command: ${DELETE_STMT}"
            $(${DELETE_STMT})
            DELETE_STMT_EXIT_CODE=$?
            if [ "${DELETE_STMT_EXIT_CODE}" != "0" ]; then
                echo "${OBJECT_TYPE}s delete command failed with exit code '${DELETE_STMT_EXIT_CODE}'"
                exit ${DELETE_STMT_EXIT_CODE}
            else
                echo "Script deleted ${MARKED_FOR_DELETE_COUNT} ${OBJECT_TYPE}(s)"
            fi
        else
            echo "Script did not delete ${OBJECT_TYPE}(s) older than ${MAX_LOG_AGE_IN_DAYS} days from ${BASE_LOG_FOLDER}, ENABLE_DELETE is ${ENABLE_DELETE}"
        fi
    else
        echo "Script did not found ${OBJECT_TYPE}(s) older than ${MAX_LOG_AGE_IN_DAYS} days in ${BASE_LOG_FOLDER}"
    fi
}

FIND_FILES_TO_DELETE_STATEMENT="find ${BASE_LOG_FOLDER}/*/* -type f -mtime +${MAX_LOG_AGE_IN_DAYS}"
FIND_DIRS_TO_DELETE_STATEMENT="find ${BASE_LOG_FOLDER}/*/* -type d -empty -mtime +${MAX_LOG_AGE_IN_DAYS}"

cleanup "$FIND_FILES_TO_DELETE_STATEMENT" "file"
echo "--------------------------------------"
cleanup "$FIND_DIRS_TO_DELETE_STATEMENT" "dir"

echo "Finished logs cleanup"
exit 0
