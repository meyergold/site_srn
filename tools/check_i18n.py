#!/usr/bin/env python3
"""Audit i18n de index.html : chaînes FR visibles sans traduction, et clés orphelines.

Usage : python3 tools/check_i18n.py [--verbose]

- "MANQUANTES" : textes FR présents dans le DOM (hors data-t) absents de TX_EN.
- "ORPHELINES" : clés de TX_EN qui ne correspondent plus à aucun texte du DOM
  (⚠ certaines sont utilisées par du JS dynamique ou les iframes : vérifier avant de purger).
"""
import re, html as H, sys, json, os

ROOT = os.path.join(os.path.dirname(__file__), '..')
c = open(os.path.join(ROOT, 'index.html')).read()
verbose = '--verbose' in sys.argv

def norm(s):
    return re.sub(r'\s+', ' ', s).replace('’', "'").strip()

# --- Extraire TX_EN (format simple "fr":"en") ---
def extract_dict(marker):
    i = c.find(marker)
    assert i > 0, marker
    j = c.find('};', i)
    body = c[i:j]
    return dict(re.findall(r'"((?:[^"\\]|\\.)+)"\s*:\s*"((?:[^"\\]|\\.)*)"', body))

# reposition on the big TX dicts (the two walk() dicts)
tx_starts = [m.start() for m in re.finditer(r'var TX_EN\s*=|TX_EN\s*=\s*\{', c)]
if tx_starts:
    en = extract_dict(c[tx_starts[0]:tx_starts[0]+20])
else:
    # fallback : chercher la 1re grosse table "fr":"en" après '</footer>'
    en = {}
    for m in re.finditer(r'\{\n?"[^"]{3,}":"', c):
        j = c.find('};', m.start())
        d = dict(re.findall(r'"((?:[^"\\]|\\.)+)"\s*:\s*"((?:[^"\\]|\\.)*)"', c[m.start():j]))
        if len(d) > len(en):
            en = d
en_keys = {norm(k.encode().decode('unicode_escape') if '\\u' in k else k) for k in en}

# --- Extraire les textes visibles du DOM ---
dom = re.sub(r'<(script|style|svg)\b.*?</\1>', ' ', c, flags=re.S)
texts = set()
for m in re.finditer(r'>([^<>{}]+)<', dom):
    t = norm(H.unescape(m.group(1)))
    if len(t) < 4 or t.isdigit() or re.fullmatch(r'[\W\d\s€%+·—→←×÷:;,.…]+', t):
        continue
    texts.add(t)

missing = sorted(t for t in texts if t not in en_keys and re.search(r'[a-zàéèêçûôîœ]', t))
orphans = sorted(k for k in en_keys if k not in texts)

print(f"Textes DOM analysés : {len(texts)}")
print(f"Clés TX_EN          : {len(en_keys)}")
print(f"MANQUANTES (FR sans trad EN) : {len(missing)}")
print(f"ORPHELINES (clés sans usage DOM statique) : {len(orphans)}")
if verbose:
    print("\n--- MANQUANTES ---")
    for t in missing[:200]:
        print(" •", t[:110])
    print("\n--- ORPHELINES (peuvent être utilisées par JS/iframes !) ---")
    for k in orphans[:200]:
        print(" •", k[:110])
