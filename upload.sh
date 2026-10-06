#!/usr/bin/env bash
# Deploy landing/ or website/ to its web root over explicit FTPS (lftp mirror).
#
#   us | landing  → landing/ to accelerait.us  (credentials in docs/ftp-us.txt)
#   uz | website  → website/ to accelerait.uz  (credentials in docs/ftp-uz.txt, PHP host)
#
# The credentials file holds "FTP Username: ...", "FTP server: ...",
# "FTP & explicit FTPS port: ..." and "psw: ..." lines (the Russian
# "Имя пользователя FTP:" / "FTP-сервер:" labels work too), so the password
# never lives here. Env vars FTP_USER / FTP_HOST / FTP_PORT / FTP_PASS / REMOTE_DIR
# override them.
#
# Usage:
#   ./upload.sh                  both sites, uz first (landing links point there)
#   ./upload.sh us|uz            upload new/changed files
#   ./upload.sh us|uz --dry-run  show what would be uploaded, change nothing
#   ./upload.sh us|uz --delete   also remove remote files that no longer exist locally
set -euo pipefail

cd "$(dirname "$0")"

TARGET=""
DRY=""
DELETE=""
for arg in "$@"; do
  case $arg in
    us|landing)  TARGET=us ;;
    uz|website)  TARGET=uz ;;
    --dry-run) DRY="--dry-run" ;;
    --delete)  DELETE="--delete" ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done
# No site named: deploy both, one after the other, with the same flags
if [ -z "$TARGET" ]; then
  "$0" uz "$@"
  exec "$0" us "$@"
fi

# docs/ftp-<domain>.txt holds the credentials for the folder served on that domain
case $TARGET in
  us) DIR=landing ;;
  uz) DIR=website ;;
esac
CREDS=docs/ftp-$TARGET.txt
field() { [ -f "$CREDS" ] && sed -nE "s/^$1[[:space:]]*//p" "$CREDS" | head -1 | tr -d '\r' || true; }

FTP_USER=${FTP_USER:-$(field '(FTP Username|Имя пользователя FTP):')}
FTP_HOST=${FTP_HOST:-$(field '(FTP server|FTP-сервер):')}
FTP_PORT=${FTP_PORT:-$(field 'FTP & explicit FTPS port:')}
FTP_PORT=${FTP_PORT:-21}
FTP_PASS=${FTP_PASS:-$(field psw:)}
REMOTE_DIR=${REMOTE_DIR:-/}  # FTP accounts are chrooted to their web root

for v in FTP_USER FTP_HOST FTP_PASS; do
  [ -n "${!v}" ] || { echo "$v is empty — check $CREDS" >&2; exit 1; }
done

# No lftp (e.g. Git Bash on Windows): re-run this script in an Alpine container.
# Credentials pass through the environment; CRs are stripped in case of a CRLF checkout.
if ! command -v lftp >/dev/null; then
  command -v docker >/dev/null || { echo "lftp not found (brew install lftp), and no docker to fall back on" >&2; exit 1; }
  echo "lftp not found — running in Docker (alpine + lftp)"
  export FTP_USER FTP_HOST FTP_PORT FTP_PASS REMOTE_DIR
  REPO=$(pwd -W 2>/dev/null || pwd)
  MSYS_NO_PATHCONV=1 exec docker run --rm -i -v "$REPO:/repo" -w /repo \
    -e FTP_USER -e FTP_HOST -e FTP_PORT -e FTP_PASS -e REMOTE_DIR \
    alpine:3.20 sh -c 'apk add -q bash lftp ca-certificates && bash -c "$(tr -d "\r" < upload.sh)" upload.sh "$@"' sh "$@"
fi

echo "→ ${DIR}/ (accelerait.${TARGET}): ${FTP_USER}@${FTP_HOST}:${FTP_PORT}${REMOTE_DIR} ${DRY:+(dry run)}"

# Password goes through the environment, not argv, so it doesn't show in `ps`.
export LFTP_PASSWORD=$FTP_PASS
lftp --env-password -u "$FTP_USER" -p "$FTP_PORT" "$FTP_HOST" <<EOF
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate yes
set net:max-retries 2
set net:timeout 20
set cmd:fail-exit true
# Excluded paths are neither uploaded nor removed by --delete, so the host's own
# files in the web root (cPanel quota, ACME challenges, logs, …) are left alone.
mirror --reverse --only-newer --verbose --parallel=4 $DRY $DELETE \
  --exclude-glob Dockerfile \
  --exclude-glob .dockerignore \
  --exclude-glob .DS_Store \
  --exclude-glob .ftpquota \
  --exclude-glob .user.ini \
  --exclude-glob php.ini \
  --exclude-glob error_log \
  --exclude '^\.well-known/' \
  --exclude '^cgi-bin/' \
  --exclude '^home/' \
  "$DIR/" "$REMOTE_DIR"
EOF

echo "✓ done"
