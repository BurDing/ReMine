NYT_DIR=/shared/data/qiz3/data/nyt

green=`tput setaf 2`
reset=`tput sgr0`
echo ${green}===Distant Supervision===${reset}
python src_py/distantSupervision.py --op=exe --in1=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/train.json --in2=data_remine/NYT_FBtyped.txt

echo ${green}===Tokenization===${reset}
python3 src_py/preprocessing.py --op=train --in1=$NYT_DIR/total.lemmas.txt --in2=$NYT_DIR/total.pos.txt --in3=$NYT_DIR/total.dep.txt
python3 src_py/preprocessing.py --op=chunk --in1=/shared/data/qiz3/data/nyt/total.lemmas.txt --in2=/shared/data/qiz3/data/nyt/total.pos.txt
python3 src_py/preprocessing.py --op=translate --in1=data/EN/stopwords.txt --out=tmp_remine/tokenized_stopwords.txt
python3 src_py/preprocessing.py --op=translate --in1=tmp/nyt.entities --out=tmp_remine/tokenized_quality.txt
python3 src_py/preprocessing.py --op=translate --in1=tmp/nyt.relations --out=tmp_remine/tokenized_negatives.txt

echo ${green}===Entity and Relation Mining===${reset}
bash remine_exp.sh
bash remine_seg.sh

python3 src_py/preprocessing.py --op=segment --in1=tmp_remine/tokenized_segmented_sentences.txt --out=results_remine/segmentation.txt
python3 src_py/postprocessing.py  --op=extract --in1=results_remine/segmentation.txt --in2=$NYT_DIR/total.lemmas.txt --in3=$NYT_DIR/total.pos.txt --out1=tmp/total.json

echo ${green}===Tuple Mining===${reset}
python3 src_py/postprocessing.py  --op=transformat --in1=tmp/total.json --out1=tmp/entity_position.txt
./bin/remine_baseline $NYT_DIR/total.dep_2.txt tmp/entity_position.txt $NYT_DIR/total.pos.txt tmp/shortest_paths.txt
python3 src_py/postprocessing.py --op=generatepath --in1=tmp/total.json --in2=tmp/shortest_paths.txt --in3=$NYT_DIR/total.dep_2.txt --out1=tmp/total_rm.json --out2=tmp_remine/rm_deps_train.txt
echo ${green}===Local Consistency===${reset}
python3 src_py/preprocessing.py --op=train_rm --in1=tmp/total_rm.json
bash remine_rm_exp.sh
bash remine_rm_seg.sh
python3 src_py/preprocessing.py --op=segment_rm --in1=tmp_remine/rm_tokenized_segmented_sentences.txt --out=results_remine/rm_segmentation.txt
python3 src_py/postprocessing.py --op=generatetri --in1=results_remine/rm_segmentation.txt --in2=tmp/total_rm.json --out1=tmp/train.txt --out2=tmp/entity.txt --out3=tmp/relation.txt --out4=tmp/train_rm_np.json
echo ${green}===Global Cohesiveness===${reset}
./utils/TransE/code/transe -alpha 0.001 -samples 500 -entity tmp/entity.txt -relation tmp/relation.txt -triple tmp/train.txt -output-en tmp/entity.emb -output-rl tmp/relation.emb -binary 0 -size 100 -threads 20