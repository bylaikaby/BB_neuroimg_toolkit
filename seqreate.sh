#!/bin/bash


seqreate() {
    local n=$1
    local sequence="$2"
    printf "%.0s$sequence " $(seq 1 $n)
    echo
}
