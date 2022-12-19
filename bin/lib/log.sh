NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHTGRAY='\033[0;37m'

function info {
    printf "${GREEN}[INFO]${1}${NC}\n"
}

function debug { 
    printf "${LIGHTGRAY}[DEBUG]${1}${NC}\n"
}

function error {
    printf "${RED}[ERROR]${1}${NC}\n"
    exit 1
}