from pathlib import Path

path = Path("/app/proxy/Caddyfile")
text = path.read_text()

# Plane's admin frontend uses basename="/god-mode/".
# Redirect the slashless URL and tighten the SPA matcher.
old = """    handle_path /god-mode* {
        root * /app/admin
        try_files {path} {path}/ /index.html
        file_server
    }"""

# Account for the actual upstream indentation seen in Plane AIO.
if old not in text:
    old = """        handle_path /god-mode* {
        root * /app/admin
        try_files {path} {path}/ /index.html
        file_server
    }"""

if old not in text:
    # Fallback: replace only the matcher and inject redirect directly before it.
    needle = "handle_path /god-mode* {"
    if needle not in text:
        raise SystemExit("Could not find Plane god-mode route in /app/proxy/Caddyfile")
    text = text.replace(
        needle,
        "redir /god-mode /god-mode/ 308\n\n    handle_path /god-mode/* {",
        1,
    )
else:
    indent = "        " if old.startswith("        ") else "    "
    replacement = (
        f"{indent}redir /god-mode /god-mode/ 308\n\n"
        f"{indent}handle_path /god-mode/* {{\n"
        f"{indent}    root * /app/admin\n"
        f"{indent}    try_files {{path}} {{path}}/ /index.html\n"
        f"{indent}    file_server\n"
        f"{indent}}}"
    )
    text = text.replace(old, replacement, 1)


# Embedded MinIO stays loopback-only. Plane's internal-MinIO mode exposes browser
# asset URLs as WEB_URL/<bucket>/..., so proxy the uploads bucket before SPA fallback.
upload_block = """
    handle /uploads {
        reverse_proxy 127.0.0.1:9000
    }

    handle /uploads/* {
        reverse_proxy 127.0.0.1:9000
    }

"""

if "reverse_proxy 127.0.0.1:9000" not in text:
    marker = "    handle_path /* {"
    if marker not in text:
        marker = "        handle_path /* {"
    if marker not in text:
        raise SystemExit("Could not find Plane web catch-all route")
    text = text.replace(marker, upload_block + marker, 1)

path.write_text(text)

# Sanity check: both the redirect and slash-qualified matcher must exist.
updated = path.read_text()
assert "redir /god-mode /god-mode/ 308" in updated
assert "handle_path /god-mode/* {" in updated
assert "handle /uploads {" in updated
assert "handle /uploads/* {" in updated
assert "reverse_proxy 127.0.0.1:9000" in updated
