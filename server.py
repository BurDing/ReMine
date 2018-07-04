from flask import Flask, request, render_template, jsonify, Response,json
import requests
import nltk
from nltk import word_tokenize
import subprocess
import sys,os
from subprocess import Popen, PIPE
import os.path
from flask_cors import CORS, cross_origin
import StringIO
import libtmux
import json
import spacy
from src_py.remine_online import Solver, Model


app = Flask(__name__)
#preload model for multithread
global model1
global model2
global model3
model1 = Model('tmp_remine/token_mapping.p')
# model2 = Model('tmp_remine/token_mapping_wiki.p')
# model3 = Model('tmp_remine/token_mapping_bio.p')
global model_dict
model_dict = {}

model_dict["m1"] = (model1, 'http://localhost:10086/pass_result')
# model_dict["s2"] = (model2, 'http://dmserv4.cs.illinois.edu:10087/pass_result')
# model_dict["s3"] = (model3, 'http://dmserv4.cs.illinois.edu:10088/pass_result')



print('load finish ')

cors = CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'


# @app.route('/preload')
# @cross_origin(origin='*')
# def preload():
#
#

@app.route('/')
@cross_origin(origin='*')
def render():
    return render_template('example.html')


#pass information to c++ web
@app.route('/remine', methods =['POST'])
@cross_origin(origin='*')
def senddata():
    nlp = spacy.load('en_core_web_sm')
    #get input from front end
    raw = request.form['text']
    model_choice = request.form['model']
    dep_text = StringIO.StringIO()
    token_text = StringIO.StringIO()
    pos_text = StringIO.StringIO()
    #send data to Stanford NLP java server
    doc = nlp(raw)

    for sent in doc.sents:
        token_len = len(sent)
        count = 0
        for token in sent:
            dep = ""
            if token.dep_ == "ROOT":
                dep = "0_root"
            else:
                dep = "{}_{}".format(token.head.i, token.dep_)
            if count == token_len -1 :
                token_text.write(token.lemma_ + '\n')
                pos_text.write(token.tag_ + '\n')
                dep_text.write(dep + '\n')
            else:
                token_text.write(token.lemma_ + ' ')
                pos_text.write(token.tag_ + ' ')
                dep_text.write(dep + ' ')
            count += 1


    dep_text = dep_text.getvalue().rstrip()
    token_text = token_text.getvalue().rstrip()
    pos_text = pos_text.getvalue().rstrip()
    #print(dep_text)
    #print(token_text)
    #print(pos_text)

    # begin remine-ie.sh
    answer = Solver(model_dict[model_choice][0])
    answer.tokenized_test(token_text, pos_text, dep_text)
    #print("token_int", answer.fdoc)
    #print(answer.fpos)
    #print(answer.fdep)
    response = requests.get(model_dict[model_choice][1], json ={"pos": answer.fpos, "tokens": answer.fdoc, "dep": answer.fdep, "ent": answer.fems, "mode": 0})
    remine_segmentation = response.text
    #print("remine_0 output", remine_segmentation)
    remine_seg_out = answer.mapBackv2(remine_segmentation)
    #print("map_out",remine_seg_out)
    answer.extract_transformat(remine_seg_out, token_text, pos_text)
    #print("fems::", answer.fems)
    response = requests.get(model_dict[model_choice][1], json ={"pos": answer.fpos, "tokens": answer.fdoc, "dep": answer.fdep, "ent": answer.fems, "mode": 1})
    remine_segmentation = response.text
    #print("remine_1 output",remine_segmentation)
    result = answer.translate(remine_segmentation)
    result_list = result.split('\n')[:-2]

    # for i in result_list:
    #     print(i)


    return jsonify({'tuple': result_list , 'lemma' : token_text })



if __name__=='__main__':
    #app.run(debug = True, host = '0.0.0.0',port=1111)
    app.run(debug = True, host = '0.0.0.0', port=8000)

    #create the tmux server to preload the model

    #app.run(debug = True)
    # http_server = WSGIServer(('0.0.0.0', 1111), app)
    #
    # http_server.serve_forever()
