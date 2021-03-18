#!/bin/bash

generate_documentation() {
    for folder in $(find $1 -type d | sed -e 's/$/\/ /'); do
        for file in $(ls -p $folder | grep -v / | grep .robot); do
            ./venv/bin/libdoc $folder$file $2/${file%.robot}'_doc.html'
        done
    done
}

generate_documentation $1 $2
