#java -cp corpus-processor.jar nlptools.SentenceAnnotator /shared/data/qiz3/data/nyt/train.txt /shared/data/qiz3/data/nyt/train

echo ${green}===Entity Linking===${reset}
python src_py/EntityLinker_freebase.py /shared/data/qiz3/data/nyt/train.tokens.txt /shared/data/qiz3/_Github/ReMine/data_remine/ NYT
python src_py/distantSupervision.py --op=entityLinker --in1=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/train.json --in2=data_remine/NYT_FBtyped.txt --out=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/train_annotated.json
python src_py/distantSupervision.py --op=entityExtractor --in1=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/train_annotated.json --out=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/nyt.entities
python src_py/distantSupervision.py --op=relationLinker --in1=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/train_annotated.json --in2=pickle --out=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/nyt.relations


echo ${green}===Tokenizaztion===${reset}
python3 src_py/preprocessing.py --op=train --in1=/shared/data/qiz3/data/nyt/total.lemmas.txt --in2=/shared/data/qiz3/data/nyt/total.pos.txt --in3=/shared/data/qiz3/data/nyt/total.dep.txt
python3 src_py/preprocessing.py --op=test --in1=/shared/data/qiz3/data/nyt/test.lemmas.txt --in2=/shared/data/qiz3/data/nyt/test.pos.txt --in3=/shared/data/qiz3/data/nyt/test.dep.txt
python3 src_py/preprocessing.py --op=chunk --in1=/shared/data/qiz3/data/nyt/total.lemmas.txt --in2=/shared/data/qiz3/data/nyt/total.pos.txt
python3 src_py/preprocessing.py --op=translate --in1=data/EN/stopwords.txt --out=tmp_remine/tokenized_stopwords.txt
python3 src_py/preprocessing.py --op=translate --in1=remine_extraction/ver2/nyt.entities --out=tmp_remine/tokenized_quality.txt
python3 src_py/preprocessing.py --op=translate --in1=remine_extraction/ver2/nyt.relations --out=tmp_remine/tokenized_negatives.txt

bash remine_exp.sh
bash remine_seg.sh

python3 src_py/preprocessing.py --op=segment --in1=tmp_remine/tokenized_segmented_sentences.txt --out=results_remine/segmentation.txt

echo ${green}===Entity Mining===${reset}
python3 src_py/postprocessing.py  --op=extract --in1=results_remine/segmentation.txt --in2=/shared/data/qiz3/data/nyt/test.lemmas.txt --in3=/shared/data/qiz3/data/nyt/test.pos.txt --out1=remine_extraction/ver2/test.json
python3 src_py/postprocessing.py  --op=transformat --in1=remine_extraction/ver2/train.json --out1=remine_extraction/ver2/entity_position.txt

echo ${green}===Relation Mining[Local Optimization]===${reset}
./bin/remine_baseline /shared/data/qiz3/data/nyt/total.dep_2.txt remine_extraction/ver2/entity_position.txt /shared/data/qiz3/data/nyt/total.pos.txt
python3 src_py/postprocessing.py --op=generatepath --in1=remine_extraction/ver2/train.json --in2=remine_extraction/ver2/shortest_paths.txt --in3=/shared/data/qiz3/data/nyt/total.dep_2.txt --out1=remine_extraction/ver2/train_rm.json --out2=tmp_remine/rm_deps_train.txt > remine_extraction/ver2/remine_test_part_b.txt
python3 src_py/preprocessing.py --op=train_rm --in1=remine_extraction/ver2/train_rm.json
bash remine_rm_exp.sh
bash remine_rm_seg.sh
python3 src_py/preprocessing.py --op=segment_rm --in1=tmp_remine/rm_tokenized_segmented_sentences.txt --out=results_remine/rm_segmentation.txt
python3 src_py/postprocessing.py --op=generatetri --in1=results_remine/rm_segmentation.txt --in2=remine_extraction/ver2/train_rm.json --out1=remine_extraction/ver2/train.txt --out2=remine_extraction/ver2/entity.txt --out3=remine_extraction/ver2/relation.txt --out4=remine_extraction/ver2/train_rm_np.json

echo ${green}===Knowledge Base Construction[Global Optimization]===${reset}
./utils/TransE/code/transe -alpha 0.001 -samples 500 -entity remine_extraction/ver2/entity.txt -relation remine_extraction/ver2/relation.txt -triple remine_extraction/ver2/train.txt -output-en entity.emb -output-rl relation.emb -binary 0 -size 100 -threads 20

python src_py/postprocessing.py --op=ranktri --in1=entity.emb --in2=relation.emb --in3=remine_extraction/ver2/train.txt --out1=remine_extraction/ver2/rank.txt
python src_py/postprocessing.py --op=generateoutput --in1=remine_extraction/ver2/rank.txt --in2=remine_extraction/ver2/train_rm.json --out1=remine_extraction/ver2/remine_test.txt

python3 src_py/postprocessing.py --op=study1 --in1=results_remine/segmentation.txt --in2=results_remine/segmentation_0.txt --out1=remine_extraction/ver2/study1.txt

echo ${green}===Combine===${reset}
python3 src_py/postprocessing.py --op=combine --in1=remine_extraction/ver2/remine_test.txt --in2=remine_extraction/ver2/remine_test_part_b.txt --out1=remine_extraction/ver2/remine_test_final.txt