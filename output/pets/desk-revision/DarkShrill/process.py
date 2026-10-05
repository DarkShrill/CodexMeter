"""CodexMeter-only 16-pose adapter around the bundled Pets extraction pipeline.

The uploaded Pets v2 record is deliberately not changed: its schema has fixed
frame counts. This extension reorders generated 4x4 pose grids into strips,
then uses the shipped connected-component extractor, inspector and compositor.
No pose is drawn, duplicated, blended, morphed or optically interpolated.
"""
from pathlib import Path
import argparse, json, sys
from statistics import median
from PIL import Image
SCRIPT_DIR=Path('C:/Users/e.papa/.codex/plugins/cache/openai-curated-remote/work-pets/0.1.6/skills/create-pet/scripts')
sys.path.insert(0,str(SCRIPT_DIR))
import extract_strip_frames as extract
import inspect_frames as inspect
import compose_atlas as compose
RUN=Path(__file__).parent.resolve()
STATES=list(extract.ROW_FRAME_COUNTS)
extract.ROW_FRAME_COUNTS={s:16 for s in STATES}
inspect.ROW_FRAME_COUNTS={s:16 for s in STATES}

def flatten(state):
    source=Image.open(RUN/'sources'/f'{state}.png').convert('RGBA')
    # Removing removable source background uses the official pipeline.
    source=extract.remove_chroma_background(source,(255,0,255),96)
    # ImageGen's transparent output can contain pure red/yellow matte fragments.
    # These saturated key colors are absent from Pip's orange/cream/brown fur.
    components=extract.connected_components(source)
    largest=max(c['area'] for c in components)
    seeds=[c for c in components if c['area']>=largest*.2]
    if len(seeds)!=16:
        raise ValueError(f'{state}: expected 16 independent connected poses, found {len(seeds)}')
    # Grid row boundaries are only used to reorder whole separated rows. Poses
    # are subsequently recovered by components, never by assumed cell slicing.
    ordered=sorted(seeds,key=lambda c:(c['bbox'][1]+c['bbox'][3])/2)
    rows=[ordered[i:i+4] for i in range(0,16,4)]
    spans=[(min(c['bbox'][1] for c in row),max(c['bbox'][3] for c in row)) for row in rows]
    for i in range(3):
        if spans[i][1]>=spans[i+1][0]:
            raise ValueError(f'{state}: overlapping generated rows, cannot safely reorder')
    row_height=max(bottom-top for top,bottom in spans)+8
    strip=Image.new('RGBA',(source.width*4,row_height))
    for row,(top,bottom) in enumerate(spans):
        # A whole row is fitted to its planted ground baseline. In jumping,
        # rows 1/2 contain ground-contact anchors and retain airborne lift.
        part=source.crop((0,top,source.width,bottom))
        strip.alpha_composite(part,(row*source.width,row_height-4-(bottom-top)))
    decoded=RUN/'pipeline'/'decoded'
    decoded.mkdir(parents=True,exist_ok=True)
    strip.save(decoded/f'{state}.png')
    report=extract.extract_state(decoded/f'{state}.png',state,RUN/'frames',(255,0,255),96,'components')
    # Common foot registration corrects layout jitter while preserving actual
    # air time in jumping. All frames share one scale within each state.
    frames=[Image.open(p).convert('RGBA') for p in report['frames']]
    bounds=[f.getbbox() for f in frames]
    rest_floor=max(b[3] for b in bounds)
    body_height=(bounds[0][3]-bounds[0][1]) if state=='jumping' else median(b[3]-b[1] for b in bounds)
    scale=172/body_height
    placements=[]
    for i,(frame,bbox) in enumerate(zip(frames,bounds)):
        # Use the lowest attached paws, not a changing tail, as horizontal anchor.
        alpha=frame.getchannel('A')
        band=max(2,round((bbox[3]-bbox[1])*.07))
        points=[]
        for y in range(bbox[3]-band,bbox[3]):
            for x in range(bbox[0],bbox[2]):
                if alpha.getpixel((x,y))>100: points.append(x)
        anchor=sum(points)/len(points) if points else (bbox[0]+bbox[2])/2
        # During a run, foot positions intentionally alternate: use silhouette
        # registration provided by the official extractor rather than chasing paws.
        if state.startswith('running-') or state=='jumping': anchor=96
        floor=rest_floor if state=='jumping' else bbox[3]
        placements.append((anchor,floor))
        # One shared state-wide transform, constrained by the broadest gesture.
        scale=min(scale,90/max(anchor-bbox[0],bbox[2]-anchor),190/max(1,floor-bbox[1]))
    for i,(frame,bbox,(anchor,floor)) in enumerate(zip(frames,bounds,placements)):
        resized=frame.resize((round(192*scale),round(208*scale)),Image.Resampling.LANCZOS)
        dx=round(96-anchor*scale)
        dy=round(198-floor*scale)
        shifted=Image.new('RGBA',(192,208))
        shifted.alpha_composite(resized,(dx,dy))
        b=shifted.getbbox()
        if b[0]<2 or b[2]>190 or b[1]<2:
            raise ValueError(f'{state}/{i}: registration would clip the pose; adjust shared extraction')
        shifted=compose.clear_transparent_rgb(shifted)
        shifted.save(report['frames'][i])
    report['schema']='codexmeter-16-pose-extension'
    return report

def review(states,reports):
    root=RUN/'frames'; root.mkdir(parents=True,exist_ok=True)
    manifest=root/'frames-manifest.json'
    previous=json.loads(manifest.read_text()) if manifest.exists() else {'rows':[]}
    by_state={r['state']:r for r in previous['rows']}
    by_state.update({r['state']:r for r in reports})
    manifest.write_text(json.dumps({'schema':'codexmeter-16-pose-extension','rows':list(by_state.values())},indent=2))
    old=sys.argv
    sys.argv=['inspect_frames.py','--frames-root',str(root),'--json-out',str(RUN/'qa'/'frame-review.json'),
              '--states',','.join(states),'--require-components']
    try:
        try: inspect.main()
        except SystemExit as result:
            if result.code not in (0,None):raise
    finally: sys.argv=old

def atlas():
    compose.COLUMNS=16;compose.ATLAS_WIDTH=16*192
    compose.ROW_SPECS=[(s,i,16) for i,s in enumerate(STATES)]
    image=compose.compose_from_frames(RUN/'frames')
    compose.save_outputs(image,RUN/'final'/'codexmeter-atlas.png',None)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--states',default='all')
    parser.add_argument('--atlas',action='store_true')
    args=parser.parse_args()
    states=STATES if args.states=='all' else args.states.split(',')
    reports=[flatten(s) for s in states]
    review(states,reports)
    if args.atlas: atlas()
