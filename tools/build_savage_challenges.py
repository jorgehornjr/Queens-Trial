"""Author deterministic Savage layouts; enumerate routes using the real 5x5 attacks.

Only displacement is counted (Manhattan), with enemies from wave one occupying
their landing cells during wave two. Runtime tests independently revalidate this.
"""
import itertools
import json
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CELLS = list(itertools.product(range(5), repeat=2))
RNG = random.Random(14102026)

def distance(a, b):
    return abs(a[0]-b[0])+abs(a[1]-b[1])

def landing(p):
    n = p['move_value']
    lane = p['edge_slot'] + p['edge_direction']*n
    return {'left': (n-1,lane), 'right':(5-n,lane), 'top':(lane,n-1), 'bottom':(lane,5-n)}[p['side']]

def attacks(p):
    x, y = landing(p)
    return {c for c in CELLS if (c[0]==x or c[1]==y) if p['type']=='rook'} if p['type']=='rook' else {c for c in CELLS if abs(c[0]-x)==abs(c[1]-y)}

def route(a, b, limit, occupied=()):
    queue = deque([[a]])
    seen = {a}
    while queue:
        path = queue.popleft()
        if path[-1] == b: return path
        x,y = path[-1]
        for cell in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
            if cell in CELLS and cell not in occupied and cell not in seen and distance(a,cell)<=limit:
                seen.add(cell)
                queue.append(path+[cell])
    return None

def wave(count, used_sides):
    result=[]
    for side in RNG.sample([s for s in ['left','right','top','bottom'] if s not in used_sides],count):
        choices=[]
        for slot,n,d in itertools.product(range(5),range(1,5),[-1,1]):
            if 0<=slot+n*d<5:
                p=dict(type=RNG.choice(['rook','bishop']),side=side,edge_slot=slot,edge_direction=d,move_value=n)
                if landing(p) not in [landing(q) for q in result]: choices.append(p)
        p=RNG.choice(choices)
        result.append(p)
        used_sides.add(side)
    return result

def main():
    stages=[]
    report=[]
    # Two pairs, one piece per side across both waves. Difficulty comes from the route.
    for index,(values,counts,target_middle) in enumerate([
        ([2,4],[2,2],2), ([3,3],[2,2],2), ([4,2],[2,2],1),
        ([3,4],[2,2],1), ([4,3],[2,2],1)
    ],1):
        for attempt in range(150000):
            sides=set()
            first=wave(counts[0],sides)
            second=wave(counts[1],sides)
            occupied={landing(p) for p in first}
            if len({landing(p) for p in first+second}) != sum(counts): continue
            a1=set().union(*(attacks(p)|{landing(p)} for p in first))
            a2=set().union(*(attacks(p)|{landing(p)} for p in second))
            candidates=[c for c in CELLS if c not in a2 and c not in occupied and (c[0] in [0,4] or c[1] in [0,4])]
            RNG.shuffle(candidates)
            for final in candidates:
                middles=[c for c in CELLS if c not in a1 and distance(c,final)==values[1] and route(c,final,values[1],occupied)]
                if len(middles)!=target_middle: continue
                # Reject layouts whose only route needs a detour around the first pair.
                if any(len(route(c,final,values[1],occupied))-1 != values[1] for c in middles): continue
                solutions=[]
                for start,mid in itertools.product(CELLS,middles):
                    if distance(start,mid)!=values[0]: continue
                    r1=route(start,mid,values[0]); r2=route(mid,final,values[1],occupied)
                    if r1 and r2: solutions.append(dict(start=start,middle=mid,first=r1,second=r2))
                starts={tuple(s['start']) for s in solutions}
                if not 3<=len(starts)<=12: continue
                if not any(distance(s['start'],final)==sum(values) for s in solutions): continue
                if index>=3 and len(a1)<14: continue
                stage=dict(id=100+index, name=f'Chaotic {index}', configuration='fixed',
                    mode='savage', edict_values=values, safe_spot=final,
                    preparation_seconds=10.0, seconds_per_edict=15.0, piece_waves=[first,second])
                stages.append(stage)
                report.append(dict(stage=index,attacked_first=len(a1),attacked_second=len(a2),
                    valid_starts=len(starts),valid_intermediates=len(middles),solutions=solutions))
                break
            else: continue
            break
        else: raise RuntimeError(f'No layout for stage {index}')
    (ROOT/'data/savage').mkdir(parents=True,exist_ok=True)
    (ROOT/'data/savage/challenges.json').write_text(json.dumps({'stages':stages},indent=2)+'\n',encoding='utf-8')
    (ROOT/'docs/design/savage_solutions.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    for item in report: print({k:v for k,v in item.items() if k!='solutions'})

if __name__=='__main__': main()
