#!/bin/bash 
###############################################################################
###                 XWiki Open Office/Libre Office Importer                 ###
###                                                                         ###
###  This script allow the import of Office document using a Open Office or ###
###  Libre Office Server. It uses POST method and supports batch import.    ###
###############################################################################
# ---------------------------------------------------------------------------
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
# ---------------------------------------------------------------------------

## Configuration ##

# Text color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

## Default values (Not defined as arameters) ##
XWIKI_URL='http://localhost:8080/xwiki';
XWIKI_FORM_LOGIN_URL=$XWIKI_URL"/bin/loginsubmit/XWiki/XWikiLogin";
XWIKI_OFFICE_IMPORTER_URL=$XWIKI_URL"/bin/view/XWiki/OfficeImporterResults";
XWIKI_TARGET_SPACE='Tests';
XWIKI_USERNAME='Admin';
XWIKI_PASSWORD='admin';
COOKIE_FILE='cookies.txt';
LOG_FILE_NAME='log.txt';
WORKING_DIR=$PWD;
FILE_TYPES=$MICROSOFT_WORD_FILES;

MICROSOFT_EXCEL_FILES=`ls | grep .xls`;
MICROSOFT_WORD_FILES=`ls | grep .doc`;
MICROSOFT_POWERPOINT_FILES=`ls | grep .ppt`;


## Parameters
# Program name for usage
PRGNAME=`basename $0`
#################
### Display help
usage() {
    echo "Usage: $PRGNAME [OPTIONS]"
    echo ""
    echo " This script can do the following steps easily to help you testing XWiki Open Office/Libre Office importer:"
    echo "   - Attach using POST a single file using a parameter."
    echo "   - Attach multiple/batch files using POST with several filtering options."
    echo ""
    echo "Options:"
    echo "  -s                  Import a single files, added as parameter"
    echo "  -b                  Import batch files. All document files from the current working dir. Filtering allowed. Possible values are: word, excel, powerpoint. Default is word.(Only when -b is used) "
    exit 1
}

# Login into XWiki
function LOGIN_TO_XWIKI {              
    curl --user-agent 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0' --cookie-jar $COOKIE_FILE \
        --data "j_username=$XWIKI_USERNAME&j_password=$XWIKI_PASSWORD" $XWIKI_FORM_LOGIN_URL;
    echo "Cookie Created/Logged In";
}

function LOGOUT_FROM_XWIKI {
    if [ -e $COOKIE_FILE ];then
        rm $COOKIE_FILE;
    fi
    echo "Cookie Destroyed/Logged Out";
}

function post_file {
    CURRENT_FILE="$1";
    TARGET_PAGE_NAME="${CURRENT_FILE%.*}";
    curl -s --cookie $COOKIE_FILE --request POST -F "filePath=@$CURRENT_FILE" -F "targetSpace=$TARGET_SPACE" -F "targetPage=$TARGET_PAGE_NAME" -o $LOG_FILE_NAME $XWIKI_OFFICE_IMPORTER_URL;

    RESULTS_MESSAGE=$(grep 'class=\"box' $LOG_FILE_NAME | sed -e :a -e 's/<[^>]*>//g;/</N;//ba');
    #if [[grep -e "succeeded" "$RESULTS_MESSAGE"]]
    if [[ `echo $RESULTS_MESSAGE | grep 'succeeded.'` ]]                                                                                                                                        
     then echo "${bldgrn} $CURRENT_FILE -> $RESULTS_MESSAGE ${txtrst}";
     else echo "${bldred} $CURRENT_FILE -> $RESULTS_MESSAGE ${txtrst}";
    fi
    rm -f $LOG_FILE_NAME;

}

# Parse command line arguments
while getopts "s:b:h" OPT; do
    case $OPT in
        s)  # Single file name
            LOGIN_TO_XWIKI
            SINGLE_FILE_NAME=$OPTARG;
            #echo $SINGLE_FILE_NAME;
            post_file $SINGLE_FILE_NAME;
            LOGOUT_FROM_XWIKI;
            ;;
        b)  # Batch import
            LOGIN_TO_XWIKI
            FILTER=$OPTARG;
            echo "FILTER" $FILTER;
            if [[ $FILTER == "word" ]]; then       FILE_TYPES=$MICROSOFT_WORD_FILES;
            fi
            if [[ $FILTER == "excel" ]]; then      FILE_TYPES=$MICROSOFT_EXCEL_FILES;
            fi
            if [[ $FILTER == "powerpoint" ]]; then FILE_TYPES=$MICROSOFT_POWERPOINT_FILES;
            fi
            echo "${info} Batch Import starting in directory" $WORKING_DIR
            shopt -s nullglob;
            for f in $FILE_TYPES;
            do 
               echo "${bldwht} Processing $f file.."
               post_file "$f"
            done
            echo "Batch Import ended"
            LOGOUT_FROM_XWIKI
            ;;
        h)  # Print Usage Information
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))
exit;
