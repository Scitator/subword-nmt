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

split_chars=0

vocab_min_freq=2
vocab_max_size=50000

merge_sequences=0

test_ratio=.2
test_data=
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
        --split_chars)
            split_chars=1
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
        --test_data)
            test_data=$2
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

    if [ ${test_data} ]; then
        cat ${test_data} |\
            awk -F '\t' '{print $1}' |\
            ${DIR}/clear_punctuation.py | \
            ${DIR}/lowercase.py > ${data_name}.L1.test.txt
        cat ${test_data} | \
            awk -F '\t' '{print $2}' | \
            ${DIR}/clear_punctuation.py | \
            ${DIR}/lowercase.py > ${data_name}.L2.test.txt
    fi
elif [ $clear_punctuation ]; then
    cat ${data} |\
        awk -F '\t' '{print $1}' |\
        ${DIR}/clear_punctuation.py > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' | \
        ${DIR}/clear_punctuation.py > ${data_name}.L2.txt

    if [ ${test_data} ]; then
        cat ${test_data} |\
            awk -F '\t' '{print $1}' |\
            ${DIR}/clear_punctuation.py > ${data_name}.L1.test.txt
        cat ${test_data} | \
            awk -F '\t' '{print $2}' | \
            ${DIR}/clear_punctuation.py > ${data_name}.L2.test.txt
    fi
elif [ $lowercase ]; then
    cat ${data} |\
        awk -F '\t' '{print $1}' |\
        ${DIR}/lowercase.py > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' | \
        ${DIR}/lowercase.py > ${data_name}.L2.txt

    if [ ${test_data} ]; then
        cat ${test_data} |\
            awk -F '\t' '{print $1}' |\
            ${DIR}/lowercase.py > ${data_name}.L1.test.txt
        cat ${test_data} | \
            awk -F '\t' '{print $2}' | \
            ${DIR}/lowercase.py > ${data_name}.L2.test.txt
    fi
else
    cat ${data} |\
        awk -F '\t' '{print $1}' > ${data_name}.L1.txt
    cat ${data} | \
        awk -F '\t' '{print $2}' > ${data_name}.L2.txt

    if [ ${test_data} ]; then
        cat ${test_data} |\
            awk -F '\t' '{print $1}' > ${data_name}.L1.test.txt
        cat ${test_data} | \
            awk -F '\t' '{print $2}' > ${data_name}.L2.test.txt
    fi
fi

if [-z ${test_data} ]; then
    cat ${data_name}.L1.txt | \
        ${DIR}/train_test_split_stream.py --test_ratio ${test_ratio} --seed ${seed}
    mv train.txt ${data_name}.L1.train.txt
    mv test.txt ${data_name}.L1.test.txt

    cat ${data_name}.L2.txt | \
        ${DIR}/train_test_split_stream.py --test_ratio ${test_ratio} --seed ${seed}
    mv train.txt ${data_name}.L2.train.txt
    mv test.txt ${data_name}.L2.test.txt
else
    mv ${data_name}.L1.txt ${data_name}.L1.train.txt
    mv ${data_name}.L2.txt ${data_name}.L2.train.txt
fi


if [ "$level" == "bpe" ];  then
    ${DIR}/learn_joint_bpe_and_vocab.py \
        --input ${data_name}.L1.train.txt ${data_name}.L2.train.txt \
        --symbols $bpe_symbols \
        --min-frequency $bpe_min_freq \
        --output ${data_name}.codes.txt \
        --write-vocabulary ${data_name}.L1.vocab.txt ${data_name}.L2.vocab.txt

    cat ${data_name}.L1.train.txt |\
        ${DIR}/apply_bpe.py \
            --codes ${data_name}.codes.txt \
            --vocabulary ${data_name}.L1.vocab.txt \
            --vocabulary-threshold ${vocab_min_freq} > ${data_dir}/train_sources.txt
    cat ${data_name}.L2.train.txt |\
        ${DIR}/apply_bpe.py \
            --codes ${data_name}.codes.txt \
            --vocabulary ${data_name}.L2.vocab.txt \
            --vocabulary-threshold ${vocab_min_freq} > ${data_dir}/train_targets.txt

    cat ${data_name}.L1.test.txt |\
        ${DIR}/apply_bpe.py \
            --codes ${data_name}.codes.txt \
            --vocabulary ${data_name}.L1.vocab.txt \
            --vocabulary-threshold ${vocab_min_freq} > ${data_dir}/test_sources.txt
    cat ${data_name}.L2.test.txt |\
        ${DIR}/apply_bpe.py \
            --codes ${data_name}.codes.txt \
            --vocabulary ${data_name}.L2.vocab.txt \
            --vocabulary-threshold ${vocab_min_freq} > ${data_dir}/test_targets.txt

    cat ${data_dir}/train_sources.txt ${data_dir}/train_targets.txt |\
        ${DIR}/get_vocab.py \
            --min_frequency ${vocab_min_freq} \
            --max_vocab_size ${vocab_max_size} > ${data_dir}/vocab.txt
elif [ "$level" == "char" ];  then
    cat ${data_name}.L1.train.txt ${data_name}.L2.train.txt |\
        ${DIR}/get_vocab.py \
            --delimiter '' \
            --min_frequency ${vocab_min_freq} \
            --max_vocab_size ${vocab_max_size} > ${data_dir}/vocab.txt

    if [ $split_chars ]; then
        cat ${data_name}.L1.train.txt |\
            ${DIR}/split_chars.py > ${data_dir}/train_sources.txt
        cat ${data_name}.L2.train.txt |\
            ${DIR}/split_chars.py > ${data_dir}/train_targets.txt
        cat ${data_name}.L1.test.txt |\
            ${DIR}/split_chars.py > ${data_dir}/test_sources.txt
        cat ${data_name}.L2.test.txt |\
            ${DIR}/split_chars.py > ${data_dir}/test_targets.txt
        tmp_var=$'_#_\t1'
        sed -i "1s/.*/$tmp_var/" ${data_dir}/vocab.txt
    else
        mv ${data_name}.L1.train.txt ${data_dir}/train_sources.txt
        mv ${data_name}.L2.train.txt ${data_dir}/train_targets.txt
        mv ${data_name}.L1.test.txt ${data_dir}/test_sources.txt
        mv ${data_name}.L2.test.txt ${data_dir}/test_targets.txt
    fi
elif [ "$level" == "word" ];  then
    cat ${data_name}.L1.train.txt ${data_name}.L2.train.txt |\
        ${DIR}/get_vocab.py \
            --delimiter ' ' \
            --min_frequency ${vocab_min_freq} \
            --max_vocab_size ${vocab_max_size} >  ${data_dir}/vocab.txt
    mv ${data_name}.L1.train.txt ${data_dir}/train_sources.txt
    mv ${data_name}.L2.train.txt ${data_dir}/train_targets.txt
    mv ${data_name}.L1.test.txt ${data_dir}/test_sources.txt
    mv ${data_name}.L2.test.txt ${data_dir}/test_targets.txt
else
    exit 1
fi

if [ $merge_sequences ]; then
    ${DIR}/merge_sequences.py \
        --input ${data_dir}/train_sources.txt ${data_dir}/train_targets.txt \
        --output ${data_dir}/train_sources_merged.txt ${data_dir}/train_targets_merged.txt

    mv ${data_dir}/train_sources_merged.txt ${data_dir}/train_sources.txt
    mv ${data_dir}/train_targets_merged.txt ${data_dir}/train_targets.txt

    ${DIR}/merge_sequences.py \
        --input ${data_dir}/test_sources.txt ${data_dir}/test_targets.txt \
        --output ${data_dir}/test_sources_merged.txt ${data_dir}/test_targets_merged.txt

    mv ${data_dir}/test_sources_merged.txt ${data_dir}/test_sources.txt
    mv ${data_dir}/test_targets_merged.txt ${data_dir}/test_targets.txt
fi

if [ $clear_tmp ]; then
    rm ${data_name}.L1.txt
    rm ${data_name}.L2.txt

    rm ${data_name}.L1.train.txt
    rm ${data_name}.L2.train.txt

    rm ${data_name}.L1.test.txt
    rm ${data_name}.L2.test.txt

    if [ "$level" == "bpe" ];  then
        rm ${data_name}.L1.vocab.txt
        rm ${data_name}.L2.vocab.txt
    fi
fi

paste -d '\t' ${data_dir}/train_sources.txt ${data_dir}/train_targets.txt > ${data_dir}/train.txt
paste -d '\t' ${data_dir}/test_sources.txt ${data_dir}/test_targets.txt > ${data_dir}/test.txt