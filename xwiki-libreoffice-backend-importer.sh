#!/bin/bash

XWIKI_URL='http://localhost:8080/xwiki';
XWIKI_FORM_LOGIN_URL=$XWIKI_URL"/bin/loginsubmit/XWiki/XWikiLogin";
XWIKI_OFFICE_IMPORTER_URL=$XWIKI_URL"/bin/view/XWiki/OfficeImporterResults";
COOKIE_FILE='cookies.txt';
TARGET_SPACE='Tests';
LOG_FILE_NAME='log.txt';
USERNAME='Admin';
PASSWORD='admin';

# Login into XWiki
function login {
    curl --user-agent 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13' --cookie-jar $COOKIE_FILE \
        --data "j_username=$USERNAME&j_password=$PASSWORD" $XWIKI_FORM_LOGIN_URL;
}

# login;

# Get the filename without the extension
function get_file_name {
    filename=$(basename "$1");
    filename="${filename%.*}";
}

function post_file {
    CURRENT_FILE="$1";
    TARGET_PAGE_NAME="${CURRENT_FILE%.*}";
    curl -s --cookie $COOKIE_FILE --request POST -F "filePath=@$CURRENT_FILE" -F "targetSpace=$TARGET_SPACE" -F "targetPage=$TARGET_PAGE_NAME" -o $LOG_FILE_NAME $XWIKI_OFFICE_IMPORTER_URL;

    RESULTS_MESSAGE=$(grep 'class=\"box' $LOG_FILE_NAME | sed -e :a -e 's/<[^>]*>//g;/</N;//ba');

    echo "$CURRENT_FILE -> $RESULTS_MESSAGE";
    rm -f $LOG_FILE_NAME;
}


post_file "Works.xls";
post_file "Fails.xls";
post_file "Works2.xls";
post_file "Fails2.xls";
post_file "TestPres.ppt";
post_file "CarnegieMellon.ppt";