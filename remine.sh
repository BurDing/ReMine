NYT_DIR=/shared/data/qiz3/data/nyt

green=`tput setaf 2`
reset=`tput sgr0`
#echo ${green}===Distant Supervision===${reset}
#python src_py/distantSupervision.py --op=exe --in1=/shared/data/qiz3/_Github/ReMine/remine_extraction/ver2/train.json --in2=data_remine/NYT_FBtyped.txt

echo ${green}===Tokenization===${reset}
python3 src_py/preprocessing.py --op=train --in1=$NYT_DIR/total.lemmas.txt --in2=$NYT_DIR/total.pos.txt --in3=$NYT_DIR/total.dep.txt
python3 src_py/preprocessing.py --op=chunk --in1=/shared/data/qiz3/data/nyt/total.lemmas.txt --in2=/shared/data/qiz3/data/nyt/total.pos.txt
python3 src_py/preprocessing.py --op=translate --in1=data/EN/stopwords.txt --out=tmp_remine/tokenized_stopwords.txt
python3 src_py/preprocessing.py --op=translate --in1=tmp/nyt.entities --out=tmp_remine/tokenized_quality.txt
python3 src_py/preprocessing.py --op=translate --in1=tmp/nyt.relations --out=tmp_remine/tokenized_negatives.txt

echo ${green}===Entity&Relation Mining===${reset}