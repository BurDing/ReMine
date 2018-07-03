from flask import Flask, request, render_template, jsonify, Response,json
import requests
import nltk
from nltk import word_tokenize
import subprocess
import sys,os
from subprocess import Popen, PIPE
import os.path
from gevent.wsgi import WSGIServer
from flask_cors import CORS, cross_origin
import StringIO
import libtmux
import json
from src_py.remine_online import Solver, Model


app = Flask(__name__)
#preload model for multithread
global model1
global model2
global model3
model1 = Model('tmp_remine/token_mapping.p')
model2 = Model('tmp_remine/token_mapping_wiki.p')
model3 = Model('tmp_remine/token_mapping_bio.p')
global model_dict
model_dict = {}

model_dict["s1"] = (model1, 'http://dmserv4.cs.illinois.edu:10086/pass_result')
model_dict["s2"] = (model2, 'http://dmserv4.cs.illinois.edu:10087/pass_result')
model_dict["s3"] = (model3, 'http://dmserv4.cs.illinois.edu:10088/pass_result')



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

#todo generate an api to set model.

@app.route('/vi', methods =['POST'])
@cross_origin(origin='*')
def vi():
    data = request.form['result'].split('\n')
    data.pop()
    for i in range(len(data)):
        temp = data[i].replace('\t', '|')
        temp = temp.split("|")
        temp[2] = temp[2].split(",")[:-1]
        for j in range(len(temp[2])):
            temp[2][j] = temp[2][j][1:-1]
        temp[3] = temp[3][1:]
        data[i] = temp
    return jsonify({'tuple': data})

#pass information to c++ web
@app.route('/remine', methods =['POST'])
@cross_origin(origin='*')
def senddata():
    NLP_client = CoreNLPClient(server='http://dmserv4.cs.illinois.edu:9000',
                               default_annotators=['depparse', 'lemma', 'pos'])
    #get input from front end
    data = request.data
    json_data = json.loads(data)
    raw = json_data["text"]
    model_choice = json_data["model"]
    dep_text = StringIO.StringIO()
    token_text = StringIO.StringIO()
    pos_text = StringIO.StringIO()
    #send data to Stanford NLP java server
    annotated = NLP_client.annotate(raw)

    for sentence in annotated.sentences:
        edges = sentence.depparse().to_json()
        dep_list = [''] * (len(edges)+1)
        for edge in edges:
            if edge['dep'] == "root":
                dep_list[edge['dependent']] = "0_root"
            else:
                dep_list[edge['dependent']] = "{}_{}".format(edge['governer'], edge['dep'])
        dep_text.write(' '.join(dep_list[1:]) + '\n')
        token_len = len(sentence)
        cout = 0
        for token in sentence:

            if cout == token_len -1 :
                token_text.write(token.lemma + '\n')
                pos_text.write(token.pos + '\n')
            else:
                token_text.write(token.lemma + ' ')
                pos_text.write(token.pos + ' ')
            cout += 1

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
    # app.run(debug = True, host = 'localhost', port=5000)

    #create the tmux server to preload the model

    app.run(debug = True)
    # http_server = WSGIServer(('0.0.0.0', 1111), app)
    #
    # http_server.serve_forever()
