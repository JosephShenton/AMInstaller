#!/bin/bash

## Define Variables

## AirMessage Variable

AM_PASS="cookiesandmilk"; # AirMessage connection password.
AM_PASS_ENCODED=$(printf "%s" "${AM_PASS}" | base64) # $(base64 <<< $AM_PASS);
AM_VERSION="0.3.3";
AM_DOWNLOAD="https://airmessage.org/files/server/server-v$AM_VERSION.zip";
AM_SF="1.0"; # Scan Frequency (How long between checking for new messages. In seconds)
AM_PORT="1359"; # Server Host Port.
AM_AUTO_UPDATE="true"; # Check for update automatically.
AM_SERVER_ADDR=$(dig +short myip.opendns.com @resolver1.opendns.com); # Server Address (Public IP)
#AM_SERVER_ADDR="airmessage.example.com" # Server Address (Domain)

## Environment Variables

SUDOPASS="123456789"; # Password used for SUDO command. Usually admin account password.
CURRENTUSER=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'); # Grabs active username.
SUPPORTPATH="/Users/$CURRENTUSER/Library/Application Support/AirMessage"; # Confirguation Folder
LOGSPATH="/Users/$CURRENTUSER/Library/Application Support/AirMessage/logs"; # Logs Folder
PREFSPATH="/Users/$CURRENTUSER/Library/Application Support/AirMessage/prefs.xml"; # Preferences File

## Colours

Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

## Setup Functions

xml_read_dom() {
    # https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
    local ENTITY IFS=\>
    if $ITSACOMMENT; then
        read -d \< COMMENTS
        COMMENTS="$(rtrim "${COMMENTS}")"
        return 0
    else
        read -d \< ENTITY CONTENT
        CR=$?
        [ "x${ENTITY:0:1}x" == "x/x" ] && return 0
        TAG_NAME=${ENTITY%%[[:space:]]*}
        [ "x${TAG_NAME}x" == "x?xmlx" ] && TAG_NAME=xml
        TAG_NAME=${TAG_NAME%%:*}
        ATTRIBUTES=${ENTITY#*[[:space:]]}
        ATTRIBUTES="${ATTRIBUTES//xmi:/}"
        ATTRIBUTES="${ATTRIBUTES//xmlns:/}"
    fi

    # when comments sticks to !-- :
    [ "x${TAG_NAME:0:3}x" == "x!--x" ] && COMMENTS="${TAG_NAME:3} ${ATTRIBUTES}" && ITSACOMMENT=true && return 0

    # http://tldp.org/LDP/abs/html/string-manipulation.html
    # INFO: oh wait it doesn't work on IBM AIX bash 3.2.16(1):
    # [ "x${ATTRIBUTES:(-1):1}x" == "x/x" -o "x${ATTRIBUTES:(-1):1}x" == "x?x" ] && ATTRIBUTES="${ATTRIBUTES:0:(-1)}"
    [ "x${ATTRIBUTES:${#ATTRIBUTES} -1:1}x" == "x/x" -o "x${ATTRIBUTES:${#ATTRIBUTES} -1:1}x" == "x?x" ] && ATTRIBUTES="${ATTRIBUTES:0:${#ATTRIBUTES} -1}"
    return $CR
}

xml_read() {
    # https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
    ITSACOMMENT=false
    local MULTIPLE_ATTR LIGHT FORCE_PRINT XAPPLY XCOMMAND XATTRIBUTE GETCONTENT fileXml tag attributes attribute tag2print TAGPRINTED attribute2print XAPPLIED_COLOR PROSTPROCESS USAGE
    local TMP LOG LOGG
    LIGHT=false
    FORCE_PRINT=false
    XAPPLY=false
    MULTIPLE_ATTR=false
    XAPPLIED_COLOR=g
    TAGPRINTED=false
    GETCONTENT=false
    PROSTPROCESS=cat
    Debug=${Debug:-false}
    TMP=/tmp/xml_read.$RANDOM
    USAGE="${C}${FUNCNAME}${c} [-cdlp] [-x command <-a attribute>] <file.xml> [tag | \"any\"] [attributes .. | \"content\"]
    ${nn[2]}  -c = NOCOLOR${END}
    ${nn[2]}  -d = Debug${END}
    ${nn[2]}  -l = LIGHT (no \"attribute=\" printed)${END}
    ${nn[2]}  -p = FORCE PRINT (when no attributes given)${END}
    ${nn[2]}  -x = apply a command on an attribute and print the result instead of the former value, in green color${END}
    ${nn[1]}  (no attribute given will load their values into your shell; use '-p' to print them as well)${END}"

    ! (($#)) && echo2 "$USAGE" && return 99
    (( $# < 2 )) && ERROR nbaram 2 0 && return 99
    # getopts:
    while getopts :cdlpx:a: _OPT 2>/dev/null
    do
    {
    case ${_OPT} in
        c) PROSTPROCESS="${DECOLORIZE}" ;;
        d) local Debug=true ;;
        l) LIGHT=true; XAPPLIED_COLOR=END ;;
        p) FORCE_PRINT=true ;;
        x) XAPPLY=true; XCOMMAND="${OPTARG}" ;;
        a) XATTRIBUTE="${OPTARG}" ;;
        *) _NOARGS="${_NOARGS}${_NOARGS+, }-${OPTARG}" ;;
    esac
    }
    done
    shift $((OPTIND - 1))
    unset _OPT OPTARG OPTIND
    [ "X${_NOARGS}" != "X" ] && ERROR param "${_NOARGS}" 0

    fileXml=$1
    tag=$2
    (( $# > 2 )) && shift 2 && attributes=$*
    (( $# > 1 )) && MULTIPLE_ATTR=true

    [ -d "${fileXml}" -o ! -s "${fileXml}" ] && ERROR empty "${fileXml}" 0 && return 1
    $XAPPLY && $MULTIPLE_ATTR && [ -z "${XATTRIBUTE}" ] && ERROR param "-x command " 0 && return 2
    # nb attributes == 1 because $MULTIPLE_ATTR is false
    [ "${attributes}" == "content" ] && GETCONTENT=true

    while xml_read_dom; do
    # (( CR != 0 )) && break
    (( PIPESTATUS[1] != 0 )) && break

    if $ITSACOMMENT; then
        # oh wait it doesn't work on IBM AIX bash 3.2.16(1):
        # if [ "x${COMMENTS:(-2):2}x" == "x--x" ]; then COMMENTS="${COMMENTS:0:(-2)}" && ITSACOMMENT=false
        # elif [ "x${COMMENTS:(-3):3}x" == "x-->x" ]; then COMMENTS="${COMMENTS:0:(-3)}" && ITSACOMMENT=false
        if [ "x${COMMENTS:${#COMMENTS} - 2:2}x" == "x--x" ]; then COMMENTS="${COMMENTS:0:${#COMMENTS} - 2}" && ITSACOMMENT=false
        elif [ "x${COMMENTS:${#COMMENTS} - 3:3}x" == "x-->x" ]; then COMMENTS="${COMMENTS:0:${#COMMENTS} - 3}" && ITSACOMMENT=false
        fi
        $Debug && echo2 "${N}${COMMENTS}${END}"
    elif test "${TAG_NAME}"; then
        if [ "x${TAG_NAME}x" == "x${tag}x" -o "x${tag}x" == "xanyx" ]; then
        if $GETCONTENT; then
            CONTENT="$(trim "${CONTENT}")"
            test ${CONTENT} && echo -e "${CONTENT}"
        else
            # eval local $ATTRIBUTES => eval test "\"\$${attribute}\"" will be true for matching attributes
            eval local $ATTRIBUTES
            $Debug && (echo2 "${m}${TAG_NAME}: ${M}$ATTRIBUTES${END}"; test ${CONTENT} && echo2 "${m}CONTENT=${M}$CONTENT${END}")
            if test "${attributes}"; then
            if $MULTIPLE_ATTR; then
                # we don't print "tag: attr=x ..." for a tag passed as argument: it's usefull only for "any" tags so then we print the matching tags found
                ! $LIGHT && [ "x${tag}x" == "xanyx" ] && tag2print="${g6}${TAG_NAME}: "
                for attribute in ${attributes}; do
                ! $LIGHT && attribute2print="${g10}${attribute}${g6}=${g14}"
                if eval test "\"\$${attribute}\""; then
                    test "${tag2print}" && ${print} "${tag2print}"
                    TAGPRINTED=true; unset tag2print
                    if [ "$XAPPLY" == "true" -a "${attribute}" == "${XATTRIBUTE}" ]; then
                    eval ${print} "%s%s\ " "\${attribute2print}" "\${${XAPPLIED_COLOR}}\"\$(\$XCOMMAND \$${attribute})\"\${END}" && eval unset ${attribute}
                    else
                    eval ${print} "%s%s\ " "\${attribute2print}" "\"\$${attribute}\"" && eval unset ${attribute}
                    fi
                fi
                done
                # this trick prints a CR only if attributes have been printed durint the loop:
                $TAGPRINTED && ${print} "\n" && TAGPRINTED=false
            else
                if eval test "\"\$${attributes}\""; then
                if $XAPPLY; then
                    eval echo -e "\${g}\$(\$XCOMMAND \$${attributes})" && eval unset ${attributes}
                else
                    eval echo -e "\$${attributes}" && eval unset ${attributes}
                fi
                fi
            fi
            else
            echo -e eval $ATTRIBUTES >>$TMP
            fi
        fi
        fi
    fi
    unset CR TAG_NAME ATTRIBUTES CONTENT COMMENTS
    done < "${fileXml}" | ${PROSTPROCESS}
    # http://mywiki.wooledge.org/BashFAQ/024
    # INFO: I set variables in a "while loop" that's in a pipeline. Why do they disappear? workaround:
    if [ -s "$TMP" ]; then
    $FORCE_PRINT && ! $LIGHT && cat $TMP
    # $FORCE_PRINT && $LIGHT && perl -pe 's/[[:space:]].*?=/ /g' $TMP
    $FORCE_PRINT && $LIGHT && sed -r 's/[^\"]*([\"][^\"]*[\"][,]?)[^\"]*/\1 /g' $TMP
    . $TMP
    rm -f $TMP
    fi
    unset ITSACOMMENT
}

rtrim() {
    local var=$@
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -e -n "$var"
}

trim() {
    local var=$@
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -e -n "$var"
}

echo2() { echo -e -e "$@" 1>&2; }

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

function createPrefs {
    cat >"$PREFSPATH" <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<Preferences>
    <SchemaVer>2</SchemaVer>
    <Port>${AM_PORT}</Port>
    <AutomaticUpdateCheck>${AM_AUTO_UPDATE}</AutomaticUpdateCheck>
    <ScanFrequency>${AM_SF}</ScanFrequency>
    <Password>${AM_PASS_ENCODED}</Password>
    <FirstRun>true</FirstRun>
    <FirstRun>true</FirstRun>
</Preferences>
EOF
}

function openAirMessage {
    if confirm "Did you want to start AirMessage now?" ; then
        clear;
        echo -e "Starting AirMessage";
        open "/Applications/AirMessage.app";
        echo -e "${BBlue}Server Address:${Color_Off} $AM_SERVER_ADDR";
        echo -e "${BBlue}Server Password:${Color_Off} $AM_PASS";
        echo -e "\n";
        echo -e "Thank you for using AM Installer by Joseph Shenton.";
        echo -e "https://github.com/JosephShenton/AMInstaller";
    else
        clear;
        echo -e "You can open AirMessage manually using one of the options below.";
        echo -e "\n";
        echo -e "${BBlue}Server Address:${Color_Off} $AM_SERVER_ADDR";
        echo -e "${BBlue}Server Password:${Color_Off} $AM_PASS";
        echo -e "\n";
        echo -e "GUI Based";
        echo -e "Navigate to the Applications folder and open AirMessage";
        echo -e "\n";
        echo -e "Terminal Based";
        echo -e "Run the following command";
        echo -e "open /Applications/AirMessage.app";
        echo -e "\n";
        echo -e "Thank you for using AM Installer by Joseph Shenton.";
        echo -e "https://github.com/JosephShenton/AMInstaller";
    fi
}

function finishInstall {
    createPrefs;
    echo -e "${BGreen}AirMessage has now been configured.${Color_Off}";
    echo -e "${BBlue}Server Address:${Color_Off} $AM_SERVER_ADDR";
    echo -e "${BBlue}Server Password:${Color_Off} $AM_PASS";
}

## Clear Screen
clear;

## Download AirMessage
echo -e "${BYellow}Downloading AirMessage v$AM_VERSION.${Color_Off}";
cd ~/Downloads;
curl -s -o "airmessage.zip" -L "$AM_DOWNLOAD" &> /dev/null;
echo -e "${BGreen}Successfully downloaded AirMessage v$AM_VERSION${Color_Off}";

## Unzip AirMessage
echo -e "${BYellow}Extracting AirMessage.${Color_Off}";
unzip -qq "airmessage.zip";
echo -e "${BYellow}Moving AirMessage to Applications folder.${Color_Off}";
echo -e $SUDOPASS | sudo -S rm -rf "/Applications/AirMessage.app" &> /dev/null;
echo -e $SUDOPASS | sudo -S mv "AirMessage.app" "/Applications/AirMessage.app" &> /dev/null;
echo -e "${BYellow}Removing AirMessage download.${Color_Off}";
rm "airmessage.zip";

## Configure AirMessage

if [ -d "$SUPPORTPATH" ]; then
    echo -e "${BRed}There is a pre-existing AirMessage setup.${Color_Off}";

    SF=$(xml_read "$PREFSPATH" ScanFrequency content);
    PW=$(xml_read "$PREFSPATH" Password content);
    PW_DECODED=$(echo "$PW" | base64 --decode);

    echo -e "\n";
    echo -e "${BCyan}Current Scan Frequency:${Color_Off} $SF";
    echo -e "${BBlue}New Scan Frequency:${Color_Off} $AM_SF";

    echo -e "\n";
    echo -e "${BCyan}Current Password:${Color_Off} $PW_DECODED";
    echo -e "${BBlue}New Password:${Color_Off} $AM_PASS";

    

    if confirm "Are you sure you want to override the current configuration?" ; then
        echo -e "${BYellow}Updating AirMessage Installation${Color_Off}";
        createPrefs;
        clear;
        finishInstall;
    else
        clear;
        echo -e "Cancelling override.";
        echo -e "\n";
        echo -e "Thank you for using AM Installer by Joseph Shenton.";
        echo -e "https://github.com/JosephShenton/AMInstaller";
        echo -e "\n";
        exit;
    fi
else
    echo -e "No pre-existing install found. Proceeding with clean installation.";
    mkdir "$SUPPORTPATH";
    mkdir "$LOGSPATH";
    finishInstall;
fi



## Open AirMessage

openAirMessage;
