#!/usr/bin/env python3
"""Fill prompts/edit_one.md from environment variables set by run_edit.sh."""
import os, sys
t = open(sys.argv[1], encoding="utf-8").read()
style = open(os.environ["STYLE_FILE"], encoding="utf-8").read()
subs = {
    "SCRIPT_NO": os.environ["N"], "RAW_FILE": os.environ["RAW"], "JOB_DIR": os.environ["JOB_DIR"],
    "SCRIPT_SOURCE": os.environ.get("SRC") or "NONE FOUND", "SCRIPT_DOC": os.environ.get("DOC") or "none",
    "EDITED_DIR": os.environ["EDITED_DIR"], "TITLE": os.environ["TITLE"],
    "STYLE_NAME": os.environ["STYLE_NAME"], "STYLE_BLOCK": style,
}
for k, v in subs.items():
    t = t.replace("{{" + k + "}}", v)
sys.stdout.write(t)
