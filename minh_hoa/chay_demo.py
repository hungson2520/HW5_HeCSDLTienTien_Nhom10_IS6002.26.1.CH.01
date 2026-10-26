"""Chay cac file demo toi uu truy van va tong hop thoi gian thuc thi.

Trong file demo, moi buoc can do bat dau bang mot dong
    \\echo '>>> [1b] mo ta buoc'
ngay truoc cau EXPLAIN (ANALYZE, ...) cua buoc do. Script chay moi file N lan
(mac dinh 5), lay thoi gian thuc thi o giua (median) cua tung buoc, luu dau ra
cua lan chay cuoi vao logs/ va ghi bang tong hop ra ket_qua.md.

Thoi gian lay tu dong "Execution Time: x ms" cua EXPLAIN ANALYZE, hoac dong
"Time: x ms" cua psql khi file bat \\timing (dung cho lenh khong EXPLAIN duoc,
vi du REFRESH MATERIALIZED VIEW).

Ket noi dung bien moi truong cua psql: PGHOST, PGPORT, PGUSER, PGPASSWORD,
PGDATABASE. Duong dan psql lay tu bien PSQL (mac dinh "psql").

Vi du (PowerShell):
    $env:PSQL = "E:\\Db\\pg\\bin\\psql.exe"; $env:PGDATABASE = "company_opt"
    python chay_demo.py              # chay tat ca file 01_*.sql .. 11_*.sql
    python chay_demo.py 08 09        # chi chay demo 08 va 09
    python chay_demo.py --lan 3 01   # chay demo 01, moi file 3 lan
"""

import argparse
import glob
import json
import os
import re
import statistics
import subprocess
import sys

PSQL = os.environ.get("PSQL", "psql")
HERE = os.path.dirname(os.path.abspath(__file__))
LOG_DIR = os.path.join(HERE, "logs")

STEP_RE = re.compile(r"^>>> \[(\S+)\]\s*(.*)$")
EXEC_RE = re.compile(r"Execution Time: ([\d.]+) ms")
PSQL_TIME_RE = re.compile(r"^Time: ([\d.]+) ms")
COST_RE = re.compile(r"\(cost=[\d.]+\.\.([\d.]+) rows=(\d+)")
ACTUAL_RE = re.compile(r"\(actual time=[\d.]+\.\.[\d.]+ rows=([\d.]+)")
BUFFERS_RE = re.compile(r"Buffers: shared(?: hit=(\d+))?(?: read=(\d+))?")
# Node bao ngoai: bo qua de lay node chinh ben duoi (join, scan, sort...)
WRAPPER_NODES = ("Aggregate", "Limit", "Result")


def run_file(path):
    """Chay mot file SQL bang psql, tra ve toan bo dau ra (stdout + stderr)."""
    env = dict(os.environ, PGCLIENTENCODING="UTF8")
    proc = subprocess.run(
        [PSQL, "-X", "-q", "-v", "ON_ERROR_STOP=1", "-f", os.path.basename(path)],
        cwd=os.path.dirname(path), env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    out = proc.stdout.decode("utf-8", errors="replace").replace("\r\n", "\n")
    if proc.returncode != 0:
        sys.stderr.write(out)
        raise SystemExit(f"psql loi khi chay {os.path.basename(path)}")
    return out


def parse_steps(output):
    """Tach dau ra thanh cac buoc.

    Moi buoc lay: node goc (cost tong, so khoi tong), node chinh = node dau
    tien khong phai Aggregate/Limit/Result (so dong uoc tinh va thuc te), va
    thoi gian thuc thi.
    """
    steps = []
    cur = None
    for raw in output.split("\n"):
        line = raw.strip()
        m = STEP_RE.match(line)
        if m:
            cur = {"label": m.group(1), "title": m.group(2), "plan": None,
                   "cost": None, "est_rows": None, "act_rows": None,
                   "blocks": None, "ms": None, "_key": False}
            steps.append(cur)
            continue
        if cur is None:
            continue
        if not cur["_key"] and "(cost=" in line:
            node = line.split("  (cost=")[0].lstrip("-> ").strip()
            if cur["plan"] is None:
                cur["plan"] = node
                cur["cost"] = float(COST_RE.search(line).group(1))
            elif node != cur["plan"]:
                cur["plan"] += " → " + node
            if not node.startswith(WRAPPER_NODES):
                cur["_key"] = True
                cur["est_rows"] = int(COST_RE.search(line).group(2))
                a = ACTUAL_RE.search(line)
                if a:
                    cur["act_rows"] = float(a.group(1))
            continue
        if cur["plan"] is not None and cur["blocks"] is None and line.startswith("Buffers:"):
            b = BUFFERS_RE.search(line)
            if b:
                cur["blocks"] = int(b.group(1) or 0) + int(b.group(2) or 0)
            continue
        t = EXEC_RE.search(line) or PSQL_TIME_RE.match(line)
        if t and cur["ms"] is None:
            cur["ms"] = float(t.group(1))
    for s in steps:
        del s["_key"]
    return steps


def run_demo(path, times):
    runs = []
    output = ""
    for _ in range(times):
        output = run_file(path)
        runs.append(parse_steps(output))

    stem = os.path.splitext(os.path.basename(path))[0]
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(os.path.join(LOG_DIR, stem + ".log.txt"), "w", encoding="utf-8") as f:
        f.write(output)

    # Ke hoach lay tu lan chay cuoi, thoi gian lay median cua moi lan chay
    result = runs[-1]
    for i, step in enumerate(result):
        ms = [r[i]["ms"] for r in runs if i < len(r) and r[i]["ms"] is not None]
        step["ms"] = round(statistics.median(ms), 3) if ms else None
        step["ms_all"] = ms
    with open(os.path.join(LOG_DIR, stem + ".json"), "w", encoding="utf-8") as f:
        json.dump({"file": os.path.basename(path), "times": times, "steps": result},
                  f, ensure_ascii=False, indent=1)
    return result


def fmt_num(x):
    if x is None:
        return ""
    if isinstance(x, float) and not x.is_integer():
        return f"{x:,.2f}".replace(",", " ")
    return f"{int(x):,}".replace(",", " ")


def write_summary():
    lines = [
        "# Kết quả chạy demo",
        "",
        "File này do `chay_demo.py` sinh ra. Thời gian là median của nhiều lần chạy;",
        "kế hoạch, số dòng và số khối lấy từ lần chạy cuối.",
        "",
        "- **Kế hoạch**: node gốc, rồi đến node chính (bỏ qua Aggregate/Limit/Result bọc ngoài).",
        "- **Cost ước tính**: cost tổng của node gốc, đơn vị nội bộ của PostgreSQL.",
        "- **Dòng ước tính / thực tế**: của node chính.",
        "- **Số khối**: `shared hit + read` của node gốc, tức số lần truy cập khối dữ liệu",
        "  (đơn vị chi phí mà sách dùng ở Mục 19.4–19.5).",
        "",
    ]
    for js in sorted(glob.glob(os.path.join(LOG_DIR, "*.json"))):
        with open(js, encoding="utf-8") as f:
            data = json.load(f)
        lines += [
            f"## {data['file']}  (chạy {data['times']} lần)",
            "",
            "| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |",
            "|---|---|---|---:|---:|---:|---:|---:|",
        ]
        for s in data["steps"]:
            lines.append(
                f"| {s['label']} | {s['title']} | {s['plan'] or ''} | {fmt_num(s['cost'])} "
                f"| {fmt_num(s['est_rows'])} | {fmt_num(s['act_rows'])} | {fmt_num(s['blocks'])} "
                f"| {fmt_num(s['ms'])} |"
            )
        lines.append("")
    with open(os.path.join(HERE, "ket_qua.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("demo", nargs="*", help="so thu tu demo, vi du 01 08 (mac dinh: tat ca)")
    ap.add_argument("--lan", type=int, default=5, help="so lan chay moi file (mac dinh 5)")
    args = ap.parse_args()
    sys.stdout.reconfigure(errors="replace")  # console Windows (cp1252) khong in duoc dau "→"

    files = sorted(glob.glob(os.path.join(HERE, "[0-9][0-9]_*.sql")))
    files = [f for f in files if not os.path.basename(f).startswith("00_")]
    if args.demo:
        files = [f for f in files if os.path.basename(f)[:2] in args.demo]
    for path in files:
        print(f"== {os.path.basename(path)}", flush=True)
        for s in run_demo(path, args.lan):
            print(f"  [{s['label']}] {fmt_num(s['ms']):>10} ms  {s['plan'] or ''}", flush=True)
    write_summary()


if __name__ == "__main__":
    main()
