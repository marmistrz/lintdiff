#!/bin/bash
# WARNING: more quick and dirty than lintdiff.sh! :)

hline() {
    printf %"$COLUMNS"s | tr " " "-"
}

usage() {
    echo "Usage: $0 [branch]"
}

case $# in
    0)
        BRANCH="upstream/develop"
        ;;
    1)
        if [ "$1" == "-h" ]; then
            usage
            exit 0
        else
            BRANCH="$1"
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac

RED=$(
    tput bold
    tput setaf 1
)
GREEN=$(
    tput bold
    tput setaf 2
)
RESET=$(tput sgr0)

UPDATE_CMD=rebase

nfailed=0
notify() {
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga
}

status() {
    if [ "$1" -eq 0 ]; then
        echo "${GREEN}OK${RESET}"
    else
        echo "${RED}FAIL${RESET}"
    fi
}

LINTDIFF="./lintdiff.sh -o -b $BRANCH"
git fetch upstream
git $UPDATE_CMD upstream/develop

commands=(
    "$LINTDIFF pylint --disable=R apps golem gui scripts setup_util '*.py'"
    "$LINTDIFF pylint --disable=R,protected-access tests"
    "$LINTDIFF pycodestyle"
    "$LINTDIFF mypy apps golem gui scripts setup_util tests '*.py'"
)

names=(
    "pylint main"
    "pylint tests"
    "pycodestyle"
    "mypy"
)

for i in "${!names[@]}"; do
    printf "%-20s" "${names[$i]}..."
    outputs[$i]=$(${commands[$i]} 2>&1)
    exitcode[$i]=$?
    status ${exitcode[$i]}
done

for i in "${!names[@]}"; do
    if [ ${exitcode[$i]} -ne 0 ]; then
        let "nfailed++"

        hline
        echo "${names[$i]} failed, output:"
        echo -e "\n"
        echo "${outputs[$i]}"
        hline
    fi
done

if [ $nfailed -gt 0 ]; then
    echo "Errors occurred, summary:"
    for i in "${!names[@]}"; do
        printf "%-20s" "${names[$i]}..."
        status ${exitcode[$i]}
    done
fi

notify &>/dev/null
