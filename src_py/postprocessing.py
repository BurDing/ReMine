import sys
import argparse,json,operator

class PostProcessor(object):
	def extract(self,test_file,json_file,pos_file,output):
		with open(test_file,'r') as IN, open(json_file, 'r') as IN_JSON, open(pos_file, 'r') as IN_POS, open(output,'w') as OUT:
			e_not_found = 0
			r_not_found = 0
			for line, json_line, pos_line in zip(IN, IN_JSON, IN_POS):
				pred=[]
				pred_rm = []
				for item in line.split(']_['):
					if ':EP' in item:
						pred.append(item.rstrip(' :EP').strip().replace('(','-LRB-').replace(')','-RRB-'))
				tmp = {}
				tmp['tokens'] = json_line.strip().split(' ')
				tmp['pos'] = pos_line.strip().split(' ')
				#exists = set()
				cur_max = dict()
				tmp['entityMentions'] = []
				ptr = 0
				for e in pred:
					window_size=e.count(' ') + 1
				
					found=False
					#ptr = 0
					while ptr+window_size <= len(tmp['tokens']):
						if ' '.join(tmp['tokens'][ptr:ptr+window_size]) == e:
							found=True
							break
						ptr+=1
					#if found and (ptr, ptr+window_size) not in exists:
					if not found:
						ptr = 0 
						e_not_found += 1
					if found:
						if ptr+window_size not in cur_max:
							cur_max[ptr+window_size] = ptr
							#tmp['entityMentions'].append([ptr, ptr+window_size, e])
						ptr+=window_size
				#keys = cur_max.keys().sort(reverse=True)
				ptr = len(tmp['tokens'])
				while ptr > 0:
					if ptr in cur_max:
						tmp['entityMentions'].append([cur_max[ptr], ptr, ' '.join(tmp['tokens'][cur_max[ptr]:ptr])])
						ptr = cur_max[ptr]
					else:
						ptr -= 1
					
				#tmp['entityMentions'] = list(exists)
				tmp['entityMentions'].sort(key=operator.itemgetter(1))
				OUT.write(json.dumps(tmp) + '\n')
			print("#entity not found:",e_not_found)

	def transformat(self, file_path, output):
		with open(file_path) as IN, open(output, 'w') as OUT:
			for line in IN:
				tmp = json.loads(line)
				ems = ''
				for em in tmp['entityMentions']:
					if len(em[2]) > 0:
						ems += str(em[0]) + '_'  + str(em[1]) + ' '
				OUT.write(ems.strip()+'\n')

	def generatePathwords(self, input_json, input_pair, input_dep, out, out2):
		self.punc = {'.',',','"',"'",'?',':',';','-','!','-lrb-','-rrb-','``',"''", ''}
		fout = open(out2, 'w')
		with open(input_json, 'r') as IN, open(input_pair, 'r') as SEG, open(input_dep, 'r') as DEP, open(out, 'w') as OUT:
			cnt = 1
			for line, line_seg, line_dep in zip(IN, SEG, DEP):
				tmp = json.loads(line)
				deps = line_dep.strip().split(' ')
				rm_indices = dict()
				
				#for rm in tmp['relationMentions']:
				#	rm_indices[(rm[0], rm[1] - 1)] = rm[2]
				#print rm_indices
				tokens = tmp['tokens']
				tags = tmp['pos']
				entityMentions = tmp['entityMentions']
				for item in line_seg.split('<>'):
					dump = {}
					annotation = item.split('\t')
					#print annotation
					if len(annotation) == 1 or len(annotation[1]) == 0:
						continue
					ranges = list(map(lambda x:int(x)-1, annotation[1].strip().split(' ')))
					if len(ranges) == 1 and tokens[ranges[0]] in self.punc:
						continue
					idx1 = int(annotation[0].split(' ')[0])
					idx2 = int(annotation[0].split(' ')[1])
					#ranges = range(entityMentions[idx1][0],entityMentions[idx1][1]) +\
					#ranges + range(entityMentions[idx2][0],entityMentions[idx2][1])
					#ranges = map(lambda x:str(x[0])+'_'+x[1],sorted(list(ranges)))
					#print ranges
					dump['tokens'] = list(map(lambda x: tokens[x], ranges))
					dump['pos'] = list(map(lambda x: tags[x], ranges))
					dump['entityMentions'] = [entityMentions[idx1], entityMentions[idx2]]
					for i in ranges:
						fout.write(str(deps[i]) + '\n')
					OUT.write(json.dumps(dump) + '\n')
					#OUT.write(entityMentions[idx1][2] + ' ')
					#OUT.write(' '.join(ranges) + ' ' + entityMentions[idx2][2] + '\n')
				cnt += 1
				#if cnt > 10:
				#	break	
				#return
					#OUT.write()
				#print json.dumps(new_line)
				#OUT.write(json.dumps(new_line) + '\n')
			print(cnt)
		fout.close()

	def loadRMTest(self, test_file,json_file,output, out1,out2):
		self.punc = ['.',',','"',"'",'?',':',';','-','!','(',')','``',"''", '']
		print(output)
		ems=set()
		rms=set()
		with open(test_file,'r') as IN, open(json_file, 'r') as IN_JSON, open(output,'w') as OUT:
			for line, json_line in zip(IN, IN_JSON):
				pred=[]
				for item in line.split(']_['):
					if ':RP' in item:
						item = item.rstrip(' :RP').lower().replace(' ', '_')
						if item not in self.punc:
							rms.add(item)
					#if ' ' in item:
					#if ' ' in item.strip():
							pred.append(item)
				if len(pred) > 0:
					tmp = json.loads(json_line)['entityMentions']
					em_1 = tmp[0][2].lower().replace(' ', '_')
					em_2 = tmp[1][2].lower().replace(' ', '_')
					ems.add(em_1)
					ems.add(em_2)
					OUT.write(em_1 +' '+ em_2 + ' '+','.join(pred) + '\n')
		with open(out1, 'w') as w1, open(out2, 'w') as w2:
			for i in list(ems):
				w1.write(i+'\n')
			for i in list(rms):
				w2.write(i+'\n')

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description="Run node2vec.")
	parser.add_argument('--in1', nargs='?', default='graph/karate.edgelist',
	                    help='Input graph path')
	parser.add_argument('--in2', nargs='?', default='graph/karate.edgelist',
	                    help='Input graph path')
	parser.add_argument('--in3', nargs='?', default='graph/karate.edgelist',
	                    help='Input graph path')

	parser.add_argument('--out1', nargs='?', default='emb/karate.emb',
	                    help='Embeddings path')
	parser.add_argument('--out2', nargs='?', default='emb/karate.emb',
	                    help='Embeddings path')
	parser.add_argument('--out3', nargs='?', default='emb/karate.emb',
	                    help='Embeddings path')

	parser.add_argument('--op', help='Type of supervision')

	args = parser.parse_args()
	tmp = PostProcessor()
	if args.op == 'extract':
		tmp.extract(args.in1, args.in2, args.in3, args.out1)
	elif args.op == 'transformat':
		tmp.transformat(args.in1, args.out1)
	elif args.op == 'generatepath':
		tmp.generatePathwords(args.in1, args.in2, args.in3, args.out1, args.out2)
	elif args.op == 'generatetri':
		tmp.loadRMTest(args.in1, args.in2, args.out1, args.out2, args.out3)