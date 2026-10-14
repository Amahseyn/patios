"""Regenerate CatIos/Localizable.xcstrings from build-extracted keys + fa_translations.py.
Usage: build the app once, then run `python3 scripts/build_xcstrings.py`."""
import glob, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from fa_translations import FA

keys = set(FA)
for f in glob.glob('.derived/Build/Intermediates.noindex/CatIos.build/Debug-iphonesimulator/CatIos.build/Objects-normal/arm64/*.stringsdata'):
    for tbl in json.load(open(f)).get('tables', {}).values():
        keys.update(e['key'] for e in tbl)

strings, missing = {}, []
for k in sorted(keys):
    if k in FA:
        strings[k] = {"localizations": {"fa": {"stringUnit": {"state": "translated", "value": FA[k]}}}}
    else:
        strings[k] = {}
        if any(c.isalpha() for c in k) and not k.startswith('%'):
            missing.append(k)
out = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
Path('CatIos/Localizable.xcstrings').write_text(json.dumps(out, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
print(f"{len(strings)} keys, {sum(1 for k in strings if k in FA)} translated; untranslated alpha keys: {missing}")
