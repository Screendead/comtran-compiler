#!/usr/bin/env python3
"""Build pitch/index.html from pitch/template.html, the cards in pitch/calls/
and the uploaded video URLs in pitch/videos.json."""
import glob, json, os

HERE = os.path.dirname(os.path.abspath(__file__))
cards = [json.load(open(p)) for p in glob.glob(os.path.join(HERE, "calls", "*.json"))]
cards.sort(key=lambda c: c["storyboard"]["meta"]["number"])
for c in cards:
    c.pop("storyboard", None)
    c.pop("sources", None)
    c.pop("recommendation_changed", None)
vpath = os.path.join(HERE, "videos.json")
videos = json.load(open(vpath)) if os.path.exists(vpath) else {}
page = open(os.path.join(HERE, "template.html")).read()
page = page.replace("/*CARDS*/[]", json.dumps(cards, ensure_ascii=False).replace("</", "<\\/"))
page = page.replace("/*VIDEOS*/{}", json.dumps(videos))
open(os.path.join(HERE, "index.html"), "w").write(page)
print(f"{len(cards)} cards, {len(videos)} videos")
