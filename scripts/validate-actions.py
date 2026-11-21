#!/usr/bin/env python3
"""Static checks for the composite actions in actions/ and for every workflow that calls them.

  * each action is a kebab-case folder with a valid composite action.yml
  * every `run:` step declares `shell: bash` and contains no ${{ }} expression (put values in env:)
  * every `uses: KMM-ZONE/open-flows/actions/<name>@...` / `./actions/<name>` call passes only declared inputs,
    passes all required inputs, and reads only declared outputs
  * actions are leaves: they never call other actions of this repository
  * (if shellcheck is installed) every script in actions and workflows passes shellcheck at style level

Needs PyYAML.  Usage: python3 scripts/validate-actions.py
"""
import glob, os, re, shutil, subprocess, sys
import yaml

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
REMOTE = re.compile(r"^KMM-ZONE/open-flows/actions/([a-z0-9-]+)@v[0-9][0-9A-Za-z.+-]*$")
LOCAL = re.compile(r"^\./actions/([a-z0-9-]+)$")
errors = []

def err(msg): errors.append(msg); print("ERROR:", msg)

actions = {}
for path in sorted(glob.glob(f"{ROOT}/actions/*/action.yml")):
    name = os.path.basename(os.path.dirname(path))
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name): err(f"actions/{name}: folder must be kebab-case")
    spec = yaml.safe_load(open(path))
    actions[name] = spec
    if spec.get("runs", {}).get("using") != "composite": err(f"actions/{name}: must be a composite action")
    for key in ("name", "description"):
        if not spec.get(key): err(f"actions/{name}: missing {key}")
    for k, v in (spec.get("inputs") or {}).items():
        if not v.get("description"): err(f"actions/{name}: input '{k}' has no description")
    for k, v in (spec.get("outputs") or {}).items():
        if not v.get("description") or not v.get("value"): err(f"actions/{name}: output '{k}' needs description and value")
    for i, step in enumerate(spec["runs"]["steps"]):
        run = step.get("run")
        if run is not None:
            if step.get("shell") != "bash": err(f"actions/{name}: step {i + 1} needs 'shell: bash'")
            if "${{" in run: err(f"actions/{name}: step {i + 1} has a ${{{{ }}}} expression in its script - pass it through env:")
        uses = step.get("uses", "")
        if uses.startswith("KMM-ZONE/open-flows") or uses.startswith("./actions/"):
            err(f"actions/{name}: actions must be leaves but step {i + 1} uses {uses}")
        if uses and "@" in uses and not re.search(r"@(v\d+|[0-9a-f]{40})$", uses) and not uses.startswith("."):
            err(f"actions/{name}: '{uses}' is not pinned to a major tag or commit SHA")

calls = 0
for wf in sorted(glob.glob(f"{ROOT}/.github/workflows/*.yml")):
    doc = yaml.safe_load(open(wf))
    text = open(wf).read()
    for jname, job in (doc.get("jobs") or {}).items():
        ids = {}
        for step in job.get("steps", []) or []:
            uses = step.get("uses", "")
            m = REMOTE.match(uses) or LOCAL.match(uses)
            if not m:
                if "KMM-ZONE/open-flows/actions" in uses or uses.startswith("./actions/"):
                    err(f"{os.path.basename(wf)}: malformed action reference '{uses}'")
                continue
            calls += 1
            name = m.group(1)
            where = f"{os.path.basename(wf)}:{jname}:{step.get('name', uses)}"
            if name not in actions: err(f"{where}: action '{name}' does not exist"); continue
            spec = actions[name]
            declared = spec.get("inputs") or {}
            given = step.get("with") or {}
            for k in given:
                if k not in declared: err(f"{where}: unknown input '{k}' for actions/{name}")
            for k, v in declared.items():
                if v.get("required") and k not in given: err(f"{where}: missing required input '{k}' for actions/{name}")
            if step.get("id"): ids[step["id"]] = name
        for sid, name in ids.items():
            declared = set((actions[name].get("outputs") or {}).keys())
            for m in re.finditer(rf"steps\.{re.escape(sid)}\.outputs\.([A-Za-z0-9_-]+)", text):
                if m.group(1) not in declared:
                    err(f"{os.path.basename(wf)}:{jname}: steps.{sid}.outputs.{m.group(1)} - actions/{name} has no such output")

def shellcheck(label, script):
    # ${{ }} expressions are replaced by a placeholder so that only the shell code is analysed
    script = re.sub(r"\$\{\{.*?\}\}", "EXPR", script, flags=re.S)
    r = subprocess.run(["shellcheck", "-s", "bash", "-S", "style", "-"], input=script, capture_output=True, text=True)
    if r.returncode != 0: err(f"{label}: shellcheck\n{r.stdout}")

if shutil.which("shellcheck"):
    for name, spec in actions.items():
        for step in spec["runs"]["steps"]:
            if step.get("run") and "python3 - <<" not in step["run"]:
                shellcheck(f"actions/{name}", step["run"])
    for wf in sorted(glob.glob(f"{ROOT}/.github/workflows/*.yml")):
        doc = yaml.safe_load(open(wf))
        for jname, job in (doc.get("jobs") or {}).items():
            default_shell = ((job.get("defaults") or {}).get("run") or {}).get("shell", "bash")
            for step in job.get("steps", []) or []:
                if step.get("run") and step.get("shell", default_shell) == "bash":
                    shellcheck(f"{os.path.basename(wf)}:{jname}:{step.get('name', '')}", step["run"])
else:
    print("note: shellcheck not installed - skipping script checks")

print(f"{len(actions)} actions, {calls} action calls checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
