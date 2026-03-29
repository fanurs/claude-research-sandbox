#!/usr/bin/env python3
"""Send session report email.

Default implementation uses the Resend API (https://resend.com).
To use a different provider, replace the send_email() function:
  - SendGrid: POST https://api.sendgrid.com/v3/mail/send
  - Mailgun:  POST https://api.mailgun.net/v3/<domain>/messages
  - Postmark: POST https://api.postmarkapp.com/email
  - SMTP:     use smtplib instead of urllib
Adjust the API URL, headers, payload format, and env var name accordingly.
"""
import base64
import html as html_mod
import json
import os
import re
import sys
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

RECIPIENT = os.environ.get("REPORT_EMAIL_TO", "__REPORT_EMAIL_TO__")
FROM_ADDR = os.environ.get("RESEND_FROM", "__RESEND_FROM__")


def find_latest_report():
    reports_dir = Path("/workspace/reports")
    reports = sorted(
        reports_dir.glob("*.md"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return reports[0] if reports else None


def extract_images(report_path, content):
    images = []
    for match in re.finditer(r"!\[.*?\]\((.+?)\)", content):
        img_path = Path(match.group(1))
        if not img_path.is_absolute():
            img_path = report_path.parent / img_path
        if img_path.exists() and img_path.stat().st_size < 5_000_000:
            images.append(img_path)
    return images


def send_email(subject, html_body, attachments=None):
    api_key = os.environ.get("RESEND_API_KEY")
    if not api_key:
        print("RESEND_API_KEY not set, skipping email", file=sys.stderr)
        return False

    payload = {
        "from": FROM_ADDR,
        "to": [RECIPIENT],
        "subject": subject,
        "html": html_body,
    }
    if attachments:
        payload["attachments"] = attachments

    req = Request(
        "https://api.resend.com/emails",
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": "research-sandbox/1.0",
        },
    )

    try:
        resp = urlopen(req)
        result = json.loads(resp.read())
        print(f"Email sent: {result.get('id', 'ok')}")
        return True
    except HTTPError as e:
        print(f"Email failed: {e.code} {e.read().decode()}", file=sys.stderr)
        return False


def send_test():
    return send_email(
        subject="[Research] Test email",
        html_body=(
            "<p>This is a test email from the research sandbox.</p>"
            "<p>Email notifications are working.</p>"
        ),
    )


def send_report(report_path=None):
    if report_path is None:
        report_path = find_latest_report()
    else:
        report_path = Path(report_path)

    if not report_path or not report_path.exists():
        print("No report found, skipping email", file=sys.stderr)
        return False

    content = report_path.read_text()
    escaped = html_mod.escape(content)
    html_body = (
        "<html><body>"
        f"<h2>{html_mod.escape(report_path.stem)}</h2>"
        '<pre style="font-family: monospace; font-size: 14px; '
        f'white-space: pre-wrap; max-width: 800px;">{escaped}</pre>'
        "</body></html>"
    )

    images = extract_images(report_path, content)
    attachments = []
    for img in images:
        b64 = base64.b64encode(img.read_bytes()).decode()
        attachments.append({"filename": img.name, "content": b64})

    subject = f"[Research] {report_path.stem}"
    return send_email(subject, html_body, attachments or None)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        sys.exit(0 if send_test() else 1)
    elif len(sys.argv) > 1:
        sys.exit(0 if send_report(sys.argv[1]) else 1)
    else:
        sys.exit(0 if send_report() else 1)
