from pathlib import Path
import re

path = Path("/etc/supervisor/conf.d/supervisor.conf")
text = path.read_text()

required = 'USE_MINIO="1",BUCKET_NAME="uploads",AWS_S3_BUCKET_NAME="uploads",MINIO_ENDPOINT_SSL="0"'
programs = ("api", "worker", "beat", "migrator")

def patch_section(src, program):
    pattern = re.compile(rf'(?ms)(^\[program:{re.escape(program)}\]\n)(.*?)(?=^\[program:|\Z)')
    m = pattern.search(src)
    if not m:
        raise SystemExit(f"Supervisor program not found: {program}")

    header, body = m.group(1), m.group(2)
    if 'USE_MINIO="1"' in body:
        return src

    lines = body.splitlines()
    env_idx = next((i for i, line in enumerate(lines) if line.startswith("environment=")), None)

    if env_idx is None:
        insert_at = next((i + 1 for i, line in enumerate(lines) if line.startswith("command=")), 0)
        lines.insert(insert_at, "environment=" + required)
    else:
        current = lines[env_idx][len("environment="):].rstrip(",")
        lines[env_idx] = "environment=" + current + "," + required

    new_body = "\n".join(lines)
    if body.endswith("\n"):
        new_body += "\n"

    return src[:m.start()] + header + new_body + src[m.end():]

for program in programs:
    text = patch_section(text, program)

path.write_text(text)

result = path.read_text()
for program in programs:
    m = re.search(rf'(?ms)^\[program:{re.escape(program)}\]\n(.*?)(?=^\[program:|\Z)', result)
    assert m and 'USE_MINIO="1"' in m.group(1)
