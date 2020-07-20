#!/bin/bash

#init

if_recursive=0
if_verbal=0
all_paths=()
all_full_paths=()
not_decompresed=0
yes_decompressed=0

#functions

check_location(){
    i=0
    location=$1

    while read direction
        do
        arr[i]=$direction
        let i++
    done < <(find ~/ -name "$location")
    k=1
    if [ $i -gt 1 ]; then
        echo "there are fiew files match your discription of $location : "
        echo
        for dir in ${arr[@]}
            do
            echo "$k) $dir"
            let k++
        done
        echo
        read -p "please choose the num of file you ment: " num
        let num=num-1
        all_full_paths+=(${arr[num]})
    elif [ $i -eq 1 ]
    then
        all_full_paths+=(${arr[0]})
    elif [ $i -eq 0 ]
    then
        return 0
    fi
    return 1
}

check_arguments(){
    while getopts ':vr' OPTION; do
    case "$OPTION" in
        v)
            if_verbal=1
            ;;
        r)
            if_recursive=1
            ;;
        ?)
            echo "***ERROR****"
            echo "flag wasnt recognized." 
            exit 1
            ;;
    esac
    done
    shift $((OPTIND -1))

    while [ ! -z "$1" ];
    do
        all_paths+=($1)
        shift
    done

    
    if [ ${#all_paths[@]} -eq 0 ]; then
    echo "****ERROR***"
    echo "no files to zip were entered"
    exit 1
    fi
}

check_zip(){
    if [ $1 -eq 0 ]; then
            let yes_decompressed+=1
            if [ $if_verbal -eq 1 ]; then 
                echo "$(basename "$2") decompressed"
            fi
        else
        let not_decompresed+=1
            if [ $if_verbal -eq 1 ]; then
                echo "$2 faild to decompress"
            fi
    fi

}


decompress_file(){
    

    if file "$1" | grep -q "Zip archive" ; then
        unzip -od $(dirname "$1") $1 &>/dev/null && rm $1 &>/dev/null
        check_zip $? $1
    elif file "$1" | grep -q "gzip" ; then
        gunzip $1 &>/dev/null
        check_zip $? $1
    elif file "$1" | grep -q "bzip2" ; then
        bunzip2 $1 &>/dev/null
        check_zip $? $1
    elif file "$1" | grep -q "compress'd" ; then
        uncompress $1 &>/dev/null
        check_zip $? $1
    else
        if [ $if_verbal -eq 1 ]; then 
            echo "$(basename "$2") ignored - was not zipped"
        fi
        let not_decompresed+=1
    fi



}

#main:

check_arguments $*

for path in ${all_paths[@]}; do
    check_location $path
    if [ $? -eq 0 ]; then
        echo "there were no files maching $path desccription"
        exit 1
    fi

    echo 
done

for path in ${all_full_paths[@]}; do
    if [ -f $path  ]; then
        decompress_file $path
    else
        if [ $if_recursive -eq 1 ]; then
            for file in $(find $path -type f); do
                decompress_file $file
            done
        else
            for file in $(find $path -maxdepth 1 -type f); do
                decompress_file $file
            done
        fi
    fi
done

echo "decompresed $yes_decompressed files"
exit $not_decompresed



#coments

# gzip :
#     f1.gz: gzip compressed data, was "f1", last modified: Sun Jun 14 18:54:19 2020, from Unix
# zip :
#     zipped-x2.zip: Zip archive data, at least v1.0 to extract
# bzip2:
#     f2.bz2: bzip2 compressed data, block size = 900k
# compress:
#     f3.Z: compress'd data 16 bits


