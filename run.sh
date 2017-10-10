#java -cp corpus-processor.jar nlptools.SentenceAnnotator /shared/data/qiz3/data/nyt/train.txt /shared/data/qiz3/data/nyt/train

echo ${green}===Tokenizaztion===${reset}
python3 src_py/preprocessing.py --op=train --in1=/shared/data/qiz3/data/nyt/train.lemmas.txt --in2=/shared/data/qiz3/data/nyt/train.pos.txt --in3=/shared/data/qiz3/data/nyt/train.dep.txt
python3 src_py/preprocessing.py --op=chunk --in1=/shared/data/qiz3/data/nyt/train.lemmas.txt --in2=/shared/data/qiz3/data/nyt/train.pos.txt
python3 src_py/preprocessing.py --op=translate --in1=data/EN/stopwords.txt --out=tmp_remine/tokenized_stopwords.txt
python3 src_py/preprocessing.py --op=translate --in1=data_remine/nyt_6k_quality.txt --out=tmp_remine/tokenized_quality.txt
python3 src_py/preprocessing.py --op=translate --in1=data_remine/nyt_6k_negatives.txt --out=tmp_remine/tokenized_negatives.txt

bash remine_exp.sh
bash remine_seg.sh

python3 src_py/preprocessing.py --op=segment --in1=tmp_remine/tokenized_segmented_sentences.txt --out=results_remine/segmentation.txt

echo ${green}===Entity Mining===${reset}
python3 src_py/postprocessing.py  --op=extract --in1=results_remine/segmentation.txt --in2=/shared/data/qiz3/data/nyt/train.lemmas.txt --in3=/shared/data/qiz3/data/nyt/train.pos.txt --out1=remine_extraction/ver2/train.json
python3 src_py/postprocessing.py  --op=transformat --in1=remine_extraction/ver2/train.json --out1=remine_extraction/ver2/entity_position.txt

echo ${green}===Relation Mining[Local Optimization]===${reset}
./bin/remine_baseline /shared/data/qiz3/data/nyt/train.dep_2.txt remine_extraction/ver2/entity_position.txt /shared/data/qiz3/data/nyt/train.pos.txt remine_extraction/ver2/shortest_paths.txt
python3 src_py/postprocessing.py --op=generatepath --in1=remine_extraction/ver2/train.json --in2=remine_extraction/ver2/shortest_paths.txt --in3=/shared/data/qiz3/data/nyt/train.dep_2.txt --out1=remine_extraction/ver2/train_rm.json --out2=tmp_remine/rm_deps_train.txt
python3 src_py/preprocessing.py --op=train_rm --in1=remine_extraction/ver2/train_rm.json
bash remine_rm_exp.sh
bash remine_seg.sh
python3 src_py/preprocessing.py --op=segment_rm --in1=tmp_remine/rm_tokenized_segmented_sentences.txt --out=results_remine/segmentation.txt
python3 src_py/postprocessing.py --op=generatetri --in1=results_remine/segmentation.txt --in2=remine_extraction/ver2/train_rm.json --out1=remine_extraction/ver2/train.txt --out2=remine_extraction/ver2/entity.txt --out3=remine_extraction/ver2/relation.txt

echo ${green}===Knowledge Base Construction[Global Optimization]===${reset}
./utils/TransE/code/transe -alpha 0.001 -samples 500 -entity remine_extraction/ver2/entity.txt -relation remine_extraction/ver2/relation.txt -triple remine_extraction/ver2/train.txt -output-en entity.emb -output-rl relation.emb -binary 0 -size 100 -threads 20