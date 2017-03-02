#!/bin/bash
#
# This script compares the Maven performance for downloading artifacts, given
# two settings files. The idea is to have repositories in different order inside
# those settings files, so that we can measure which order is best for a given
# project.
#
# Execute this script inside the directory to be measured, passing four arguments:
# $1: Number of times to run the tests (to get min/max/avg of $1 tries)
# $2: The path of the project to be analysed
# $3: The path to an settings.xml
# $4: The path to another settings.xml

cleanup() {
    rm -rf "$REPO"
    cd "$OLDPWD"
    exit 1
}
trap cleanup SIGHUP SIGINT SIGTERM

build() {
    local project_dir="$1"
    local settings="$2"
    REPO=$(mktemp -u --directory --tmpdir REPO-XXXXX)

    echo "Starting build of project $(basename $project_dir) - using settings $(basename $settings) and repo dir $REPO"
    cd "$project_dir"
    local output="$(mvn --settings "$settings" -Dmaven.repo.local=$REPO clean compile)"
    [ $? -ne 0 ] && {
        echo "Error building. Maven output:"
        echo "$output"
        cleanup
    }
    cd "$OLDPWD"

    local time=$(echo "$output" | grep " Total time" | cut -d":" -f2,3)
    local central=$(echo "$output" | grep 'Downloaded: ' | grep 'http://repo1.maven.org/maven2/' | wc -l)
    local redhat=$(echo "$output" | grep 'Downloaded: ' | grep -v 'http://repo1.maven.org/maven2/' | wc -l)

    rm -rf "$REPO"
    echo "Downloads from Maven Central: $central"
    echo "Downloads from Red Hat:       $redhat"
    echo "Done in $time."
    echo
}

check_file() {
    [ "-e" "$1" ] || {
        echo "File or directory $1 does not exist."
        exit 1
    }
}

check_args() {
    [ "$#" -ne 4 ] && {
        echo "Usage: $(basename $0) <times-to-run> /path/to/project /path/to/settings.xml /path/to/another/settings.xml"
        exit 1
    }

    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "First argument must be a number"
        exit 1
    fi

    check_file "$2"
    check_file "$3"
    check_file "$4"
}

run_builds() {
    local runs="$1"
    local project_dir="$2"
    local settings1="$3"
    local settings2="$4"
    local i

    for i in $(seq 1 $runs); do
        echo "**************************"
        echo "Starting build $i of $runs"
        echo "**************************"
        echo
        build "$project_dir" "$settings1"
        build "$project_dir" "$settings2"
        echo
        echo "Build $i/$runs finished"
        echo
    done
}

check_args $*
run_builds $*

