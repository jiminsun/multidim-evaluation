#!/bin/bash
# Copyright 2020 Google and DeepMind.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to train a model on a specific language's TyDiQA-GoldP train data.

REPO=$PWD
MODEL=${1:-bert-base-multilingual-cased}
ADAPTER=${2:-attention}
LANG=${3:-en}
GPU=${4:-0}
DATA_DIR=${5:-"$REPO/download/"}
OUT_DIR=${6:-"$REPO/outputs/"}

ADAPTER=attention
TASK=tydiqa

BATCH_SIZE=4
GRAD_ACC=8

#MAXL=384
LR=3e-5
NUM_EPOCHS=10
if [ $MODEL == "bert-base-multilingual-cased" ]; then
  MODEL_TYPE="bert"
  MAXL=512
  MAX_QUERY_LEN=64
  MAX_ANSWER_LEN=30
  DOC_STRIDE=128
elif [ $MODEL == "xlm-mlm-100-1280" ] || [ $MODEL == "xlm-mlm-tlm-xnli15-1024" ]; then
  MODEL_TYPE="xlm"
  MAXL=512
  MAX_QUERY_LEN=64
  MAX_ANSWER_LEN=30
  DOC_STRIDE=128
elif [ $MODEL == "xlm-roberta-large" ] || [ $MODEL == "xlm-roberta-base" ]; then
  MODEL_TYPE="xlm-roberta"
  MAXL=512
  MAX_QUERY_LEN=64
  MAX_ANSWER_LEN=30
  DOC_STRIDE=128
elif [ $MODEL == "google/canine-s" ] || [ $MODEL == "google/canine-c" ]; then
  MODEL_TYPE="canine"
  MAXL=2048
  MAX_QUERY_LEN=256
  MAX_ANSWER_LEN=100
  DOC_STRIDE=512
elif [ $MODEL == "google/mt5-small" ] || [ $MODEL == "google/mt5-base" ] || [ $MODEL == "google/mt5-large" ]; then
  MODEL_TYPE="mt5"
  MAXL=1024
  MAX_QUERY_LEN=128
  DOC_STRIDE=256
elif [ $MODEL == "google/byt5-small" ] || [ $MODEL == "google/byt5-base" ] || [ $MODEL == "google/byt5-large" ]; then
  MODEL_TYPE="byt5"
  MAXL=1024
  MAX_QUERY_LEN=128
  DOC_STRIDE=256
fi


# Model path where trained model should be stored
MODEL_PATH=$OUT_DIR/${TASK}/adapter_${ADAPTER}_${LANG}_${MODEL}_LR${LR}_EPOCH${NUM_EPOCHS}_maxlen${MAXL}_batchsize${BATCH_SIZE}_gradacc${GRAD_ACC}
mkdir -p $MODEL_PATH

# Train on TyDiQa-GoldP $LANG train file
TASK_DATA_DIR=${DATA_DIR}/tydiqa
TRAIN_FILE=${TASK_DATA_DIR}/tydiqa-goldp-v1.1-train/tydiqa.${LANG}.train.json
PREDICT_FILE=${TASK_DATA_DIR}/tydiqa-goldp-v1.1-dev/tydiqa.${LANG}.dev.json
# tydiqa.en.train.json

# train
CUDA_VISIBLE_DEVICES=$GPU python $REPO/third_party/adapter_run_squad.py \
  --model_type ${MODEL_TYPE} \
  --task_name ${TASK} \
  --model_name_or_path ${MODEL} \
  --do_train \
  --do_eval \
  --data_dir ${TASK_DATA_DIR} \
  --train_file ${TRAIN_FILE} \
  --predict_file ${PREDICT_FILE} \
  --per_gpu_train_batch_size ${BATCH_SIZE} \
  --learning_rate ${LR} \
  --num_train_epochs ${NUM_EPOCHS} \
  --max_seq_length ${MAXL} \
  --max_query_length ${MAX_QUERY_LEN} \
  --max_answer_length ${MAX_ANSWER_LEN} \
  --doc_stride ${DOC_STRIDE} \
  --save_steps 1000 \
  --overwrite_output_dir \
  --gradient_accumulation_steps ${GRAD_ACC} \
  --warmup_steps 0.1 \
  --output_dir ${MODEL_PATH} \
  --weight_decay 0.0001 \
  --threads 8 \
  --train_lang ${LANG} \
  --eval_lang ${LANG} --adapter $ADAPTER

# predict
bash $REPO/adapter_scripts/adapter_predict_tydiqa.sh $MODEL $MODEL_PATH $TASK $GPU $DATA_DIR
