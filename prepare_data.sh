#!/usr/bin/env bash

cat ./data/data.txt |\
    awk -F '\t' '{print $1}' |\
    ./clear_punctuation.py | \
    ./lowercase.py > ./data/data.L1.txt
cat ./data/data.txt | \
    awk -F '\t' '{print $2}' | \
    ./clear_punctuation.py | \
    ./lowercase.py > ./data/data.L2.txt

./learn_joint_bpe_and_vocab.py \
    --input ./data/data.L1.txt ./data/data.L2.txt \
    -s 10000 \
    -o ./data/codes.txt \
    --write-vocabulary ./data/vocab.L1.txt ./data/vocab.L2.txt

threshold=50

cat ./data/data.L1.txt |\
    ./apply_bpe.py \
        -c ./data/codes.txt \
        --vocabulary ./data/vocab.L1.txt \
        --vocabulary-threshold ${threshold} > ./data/data.L1.bpe.txt
cat ./data/data.L2.txt |\
    ./apply_bpe.py \
        -c ./data/codes.txt \
        --vocabulary ./data/vocab.L2.txt \
        --vocabulary-threshold ${threshold} > ./data/data.L2.bpe.txt

cat ./data/vocab.L1.txt | ./clear_vocab.py --threshold $threshold > ./data/vocab.L1.clear.txt
cat ./data/vocab.L2.txt | ./clear_vocab.py --threshold $threshold > ./data/vocab.L2.clear.txt
cat ./data/vocab.L1.clear.txt ./data/vocab.L2.clear.txt > ./data/vocab.txt

./merge_sequences.py \
    --input ./data/data.L1.bpe.txt ./data/data.L2.bpe.txt \
    --output ./data/sources.txt ./data/targets.txt

cat ./data/sources.txt | ./train_test_split_stream.py
mv train.txt ./data/train_sources.txt
mv test.txt ./data/test_sources.txt

cat ./data/targets.txt | ./train_test_split_stream.py
mv train.txt ./data/train_targets.txt
mv test.txt ./data/test_targets.txt
