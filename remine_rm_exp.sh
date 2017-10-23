SEGMENTATION_MODEL=results_remine/segmentation.model
TEXT_TO_SEG=tmp_remine/raw_text_to_seg.txt
ENABLE_POS_TAGGING=1
MAX_POSITIVES=-1
THREAD=10

green=`tput setaf 2`
reset=`tput sgr0`

echo ${green}===Compilation===${reset}
make all CXX=g++ | grep -v "Nothing to be done for"

mkdir -p tmp_remine
mkdir -p results_remine
### END Compilation###

echo ${green}===Tokenization===${reset}

TOKENIZER="-cp .:tools/tokenizer/lib/*:tools/tokenizer/resources/:tools/tokenizer/build/ Tokenizer"

### END Part-Of-Speech Tagging ###

echo ${green}===Segphrasing===${reset}

if [ $ENABLE_POS_TAGGING -eq 1 ]; then
	time ./bin/remine_rm_train \
        --verbose \
        --pos_tag \
        --thread $THREAD \
        --max_positives $MAX_POSITIVES \
        --model $SEGMENTATION_MODEL
else
	time ./bin/remine_rm_train \
        --verbose \
        --thread $THREAD \
        --max_positives $MAX_POSITIVES \
        --model $SEGMENTATION_MODEL
fi

### END Segphrasing ###

#echo ${green}===Generating Output===${reset}
#python src_py/PreProcessor.py segmentation tmp_remine/nyt_6k_rm/tokenized_segmented_sentences.txt results_remine/segmentation.txt
#java $TOKENIZER -m segmentation -i $TEXT_TO_SEG -segmented tmp_remine/tokenized_segmented_sentences.txt -o results_remine/segmentation.txt -tokenized_raw tmp_remine/raw_text_to_seg.txt -tokenized_id tmp_remine/tokenized_text_to_seg.txt -c N


#python src_py/PostProcessor.py ../data/nyt/test_new.json results_remine/segmentation.txt #>> $2
#python src_py/PostProcessor.py src_py/kbp_test.json results_remine/segmentation.txt >> $2
#python src_py/PostProcessor.py ../shared_data/data/intermediate/KBP/ntest.json results_remine/segmentation.txt >> $2
#java $TOKENIZER -m translate -i tmp_remine/tokenized_segmented_sentences.txt -o results_remine/segmentation.txt -t $TOKEN_MAPPING -c N -thread $THREAD
#java $TOKENIZER -m segmentation -i $TEXT_TO_SEG -segmented tmp_remine/tokenized_segmented_sentences.txt -o results_remine/segmentation.txt -tokenized tmp_remine/tokenized_text_to_seg.txt

### END Generating Output for Checking Quality ###
