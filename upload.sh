#!/usr/bin/env bash
# Deploy site/ to the production web root over explicit FTPS (lftp mirror).
#
# Credentials are read from docs/ftp.txt (git-ignored):
#   FTP Username: user@accelerait.us
#   FTP server:   host
#   FTP & explicit FTPS port:  21
#   psw: ...
# Env vars FTP_USER / FTP_HOST / FTP_PORT / FTP_PASS / REMOTE_DIR override the file.
#
# Usage:
#   ./upload.sh            upload new/changed files
#   ./upload.sh --dry-run  show what would be uploaded, change nothing
#   ./upload.sh --delete   also remove remote files that no longer exist in site/
set -euo pipefail

cd "$(dirname "$0")"

CREDS=docs/ftp.txt
field() { [ -f "$CREDS" ] && sed -nE "s/^$1[[:space:]]*//p" "$CREDS" | head -1 | tr -d '\r' || true; }

FTP_USER=${FTP_USER:-$(field 'FTP Username:')}
FTP_HOST=${FTP_HOST:-$(field 'FTP server:')}
FTP_PORT=${FTP_PORT:-$(field 'FTP & explicit FTPS port:')}
FTP_PORT=${FTP_PORT:-21}
FTP_PASS=${FTP_PASS:-$(field 'psw:')}
# The FTP account is chrooted to the domain folder, so "/" is the web root.
REMOTE_DIR=${REMOTE_DIR:-/}

DRY=""
DELETE=""
for arg in "$@"; do
  case $arg in
    --dry-run) DRY="--dry-run" ;;
    --delete)  DELETE="--delete" ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

command -v lftp >/dev/null || { echo "lftp not found (brew install lftp)" >&2; exit 1; }
for v in FTP_USER FTP_HOST FTP_PASS; do
  [ -n "${!v}" ] || { echo "$v is empty — check $CREDS" >&2; exit 1; }
done

echo "→ ${FTP_USER}@${FTP_HOST}:${FTP_PORT}${REMOTE_DIR} ${DRY:+(dry run)}"

# Password goes through the environment, not argv, so it doesn't show in `ps`.
export LFTP_PASSWORD=$FTP_PASS
lftp --env-password -u "$FTP_USER" -p "$FTP_PORT" "$FTP_HOST" <<EOF
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate yes
set net:max-retries 2
set net:timeout 20
set cmd:fail-exit true
mirror --reverse --only-newer --verbose --parallel=4 $DRY $DELETE \
  --exclude-glob Dockerfile \
  --exclude-glob .dockerignore \
  --exclude-glob .DS_Store \
  site/ "$REMOTE_DIR"
EOF

echo "✓ done"
