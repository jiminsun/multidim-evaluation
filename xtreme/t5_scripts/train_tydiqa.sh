REPO=$PWD
MODEL=${1:-google/mt5-base}
GPU=${2:-0}
DATA_DIR=${3:-"$REPO/download/"}
OUT_DIR=${4:-"$REPO/outputs/"}

TASK=tydiqa
BATCH_SIZE=4
GRAD_ACC=8

LR=3e-4
#NUM_EPOCHS=10
MAX_STEPS=50000

if [ $MODEL == "google/mt5-small" ] || [ $MODEL == "google/mt5-base" ] || [ $MODEL == "google/mt5-large" ]; then
  MODEL_TYPE="mt5"
  MAXL=1024
  MAX_ANSWER_LEN=512
  DOC_STRIDE=256
elif [ $MODEL == "google/byt5-small" ] || [ $MODEL == "google/byt5-base" ] || [ $MODEL == "google/byt5-large" ]; then
  MODEL_TYPE="byt5"
  MAXL=4096
  MAX_ANSWER_LEN=512
  DOC_STRIDE=256
fi


# Model path where trained model should be stored
MODEL_PATH=$OUT_DIR/$TASK/${MODEL}_LR${LR}_maxlen${MAXL}_batchsize${BATCH_SIZE}_gradacc${GRAD_ACC}
mkdir -p $MODEL_PATH
mkdir -p $MODEL_PATH/cache

# train
CUDA_VISIBLE_DEVICES=$GPU python third_party/run_t5.py \
  --model_name_or_path ${MODEL} \
  --do_train \
  --dataset_name tydiqa \
  --dataset_config_name secondary_task \
  --context_column context \
  --question_column question \
  --answer_column answers \
  --max_seq_length ${MAXL} \
  --max_answer_length ${MAX_ANSWER_LEN} \
  --doc_stride ${DOC_STRIDE} \
  --output_dir ${MODEL_PATH} \
  --overwrite_output_dir \
  --overwrite_cache \
  --learning_rate ${LR} \
  --lr_scheduler_type "constant" \
  --per_device_train_batch_size ${BATCH_SIZE} \
  --gradient_accumulation_steps ${GRAD_ACC} \
  --max_steps ${MAX_STEPS} \
  --num_beams 30 \
  --save_strategy steps --save_steps 2000 \
  --val_max_answer_length ${MAX_ANSWER_LEN}




