NYT_DIR=/shared/data/qiz3/data/nyt
green=`tput setaf 2`
reset=`tput sgr0`

echo ${green}===Tokenization===${reset}
python3 src_py/preprocessing.py --op=test --in1=$NYT_DIR/test.lemmas.txt --in2=$NYT_DIR/test.pos.txt --in3=$NYT_DIR/test.dep.txt

bash remine_seg.sh
python3 src_py/preprocessing.py --op=segment --in1=tmp_remine/tokenized_segmented_sentences.txt --out=results_remine/segmentation.txt
python3 src_py/postprocessing.py  --op=extract --in1=results_remine/segmentation.txt --in2=$NYT_DIR/test.lemmas.txt --in3=$NYT_DIR/test.pos.txt --out1=tmp/test.json

echo ${green}===Tuple Mining===${reset}
python3 src_py/postprocessing.py  --op=transformat --in1=tmp/test.json --out1=tmp/entity_position.txt
./bin/remine_baseline $NYT_DIR/test.dep_2.txt tmp/entity_position.txt $NYT_DIR/test.pos.txt tmp/shortest_paths_test.txt
python3 src_py/postprocessing.py --op=generatepath --in1=tmp/test.json --in2=tmp/shortest_paths_test.txt --in3=$NYT_DIR/test.dep_2.txt --out1=tmp/test_rm.json --out2=tmp_remine/rm_deps_train.txt
python3 src_py/preprocessing.py --op=train_rm --in1=tmp/test_rm.json

bash remine_rm_seg.sh
python3 src_py/preprocessing.py --op=segment_rm --in1=tmp_remine/rm_tokenized_segmented_sentences.txt --out=results_remine/rm_segmentation.txt
python3 src_py/postprocessing.py --op=generatetri --in1=results_remine/rm_segmentation.txt --in2=tmp/test_rm.json --out1=tmp/test.txt --out2=tmp/entity.txt --out3=tmp/relation.txt --out4=tmp/train_rm_np.json

python src_py/postprocessing.py --op=ranktri --in1=tmp/entity.emb --in2=tmp/relation.emb --in3=tmp/test.txt --out1=tmp/rank.txt
python3 src_py/postprocessing.py --op=generateoutput --in1=tmp/rank.txt --in2=tmp/test_rm.json --out1=remine_test.txt