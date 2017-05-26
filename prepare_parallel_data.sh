#!/usr/bin/env bash

set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PYTHONPATH=${DIR}

# Parameters

data=./data/data.txt
clear_punctuation=0
lowercase=0

level=bpe
bpe_symbols=10000
bpe_min_freq=2

vocab_min_freq=2
vocab_max_size=50000

merge_sequences=0

test_ratio=.2
seed=42

clear_tmp=0

# Parse named args
while [ "$#" -gt 0 ]; do
    case "$1" in
        --data)
            data=$2
            shift
            shift
            ;;
        --clear_punctuation)
            clear_punctuation=1
            shift
            ;;
        --lowercase)
            lowercase=1
            shift
            ;;
        --level)
            level=$2
            shift
            shift
            ;;
        --bpe_symbols)
            bpe_symbols=$2
            shift
            shift
            ;;
        --bpe_min_freq)
            bpe_min_freq=$2
            shift
            shift
            ;;
        --vocab_min_freq)
            vocab_min_freq=$2
            shift
            shift
            ;;
        --vocab_max_size)
            vocab_max_size=$2
            shift
            shift
            ;;
        --merge_sequences)
            merge_sequences=1
            shift
            ;;
        --test_ratio)
            test_ratio=$2
            shift
            shift
            ;;
        --seed)
            seed=$2
            shift
            shift
            ;;
        --clear_tmp)
            clear_tmp=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

data_dir=$(dirname "${data}")
data_name=$(basename "$data")
data_name="${data_name%.*}"
data_name=${data_dir}/${data_name}

if [ $clear_punctuation ] && [ $lowercase ]; then
    cat ${data} |\
        awk -F '\t' '{print $1}' |\
        ${DIR}/clear_punctuation.py | \
        ${DIR}/lowercase.py > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' | \
        ${DIR}/clear_punctuation.py | \
        ${DIR}/lowercase.py > ${data_name}.L2.txt
elif [ $clear_punctuation ]; then
    cat ${data} |\
        awk -F '\t' '{print $1}' |\
        ${DIR}/clear_punctuation.py > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' | \
        ${DIR}/clear_punctuation.py > ${data_name}.L2.txt
elif [ $lowercase ]; then
    cat ${data} |\
        awk -F '\t' '{print $1}' |\
        ${DIR}/lowercase.py > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' | \
        ${DIR}/lowercase.py > ${data_name}.L2.txt
else
    cat ${data} |\
        awk -F '\t' '{print $1}' > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' > ${data_name}.L2.txt
fi

if [ "$level" == "bpe" ];  then
    ${DIR}/learn_joint_bpe_and_vocab.py \
        --input ${data_name}.L1.txt ${data_name}.L2.txt \
        --symbols $bpe_symbols \
        --min-frequency $bpe_min_freq \
        --output ${data_name}.codes.txt \
        --write-vocabulary ${data_name}.L1.vocab.txt ${data_name}.L2.vocab.txt

    cat ${data_name}.L1.txt |\
        ${DIR}/apply_bpe.py \
            --codes ${data_name}.codes.txt \
            --vocabulary ${data_name}.L1.vocab.txt \
            --vocabulary-threshold ${vocab_min_freq} > ${data_name}.sources.txt
    cat ${data_name}.L2.txt |\
        ${DIR}/apply_bpe.py \
            --codes ${data_name}.codes.txt \
            --vocabulary ${data_name}.L2.vocab.txt \
            --vocabulary-threshold ${vocab_min_freq} > ${data_name}.targets.txt

    cat ${data_name}.sources.txt ${data_name}.targets.txt |\
        ${DIR}/get_vocab.py \
            --min_frequency ${vocab_min_freq} \
            --max_vocab_size ${vocab_max_size} >  ${data_dir}/vocab.txt
elif [ "$level" == "char" ];  then
    cat ${data_name}.L1.txt ${data_name}.L2.txt |\
        ${DIR}/get_vocab.py \
            --delimiter '' \
            --min_frequency ${vocab_min_freq} \
            --max_vocab_size ${vocab_max_size} >  ${data_dir}/vocab.txt
    cp ${data_name}.L1.txt ${data_name}.sources.txt
    cp ${data_name}.L2.txt ${data_name}.targets.txt
elif [ "$level" == "word" ];  then
    cat ${data_name}.L1.txt ${data_name}.L2.txt |\
        ${DIR}/get_vocab.py \
            --delimiter ' ' \
            --min_frequency ${vocab_min_freq} \
            --max_vocab_size ${vocab_max_size} >  ${data_dir}/vocab.txt
    cp ${data_name}.L1.txt ${data_name}.sources.txt
    cp ${data_name}.L2.txt ${data_name}.targets.txt
else
    exit 1
fi


if [ $merge_sequences ]; then
    ${DIR}/merge_sequences.py \
        --input ${data_name}.sources.txt ${data_name}.targets.txt \
        --output ${data_dir}/sources.txt ${data_dir}/targets.txt
else
    cp ${data_name}.sources.txt ${data_dir}/sources.txt
    cp ${data_name}.targets.txt ${data_dir}/targets.txt
fi

cat ${data_dir}/sources.txt | \
    ${DIR}/train_test_split_stream.py --test_ratio ${test_ratio} --seed ${seed}
mv train.txt ${data_dir}/train_sources.txt
mv test.txt ${data_dir}/test_sources.txt

cat ${data_dir}/targets.txt | \
    ${DIR}/train_test_split_stream.py --test_ratio ${test_ratio} --seed ${seed}
mv train.txt ${data_dir}/train_targets.txt
mv test.txt ${data_dir}/test_targets.txt

if [ $clear_tmp ]; then
    rm ${data_name}.L1.txt
    rm ${data_name}.L2.txt

    if [ "$level" == "bpe" ];  then
        rm ${data_name}.L1.vocab.txt
        rm ${data_name}.L2.vocab.txt
    fi

    rm ${data_name}.sources.txt
    rm ${data_name}.targets.txt

    rm ${data_dir}/sources.txt
    rm ${data_dir}/targets.txt
fi
