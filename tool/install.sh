#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
source tool/activate.sh
if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo 'This installer supports Linux x64. Install the pinned Flutter SDK manually on other platforms.' >&2
  exit 1
fi
flutter_version="$(cat .flutter-version)"
mkdir -p "$FW_TOOLS_ROOT"
if [[ ! -x "$FW_TOOLS_ROOT/flutter/bin/flutter" ]]; then
  download_dir="$(mktemp -d "$FW_TOOLS_ROOT/download.XXXXXX")"
  trap 'rm -rf "$download_dir"' EXIT
  curl --fail --silent --show-error --location --retry 2 \
    https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json \
    --output "$download_dir/releases.json"
  python3 - "$download_dir/releases.json" "$flutter_version" "$download_dir" <<'PY'
import json, pathlib, sys
manifest = json.loads(pathlib.Path(sys.argv[1]).read_text())
release = next(r for r in manifest['releases'] if r['version'] == sys.argv[2]
               and r['channel'] == 'stable' and r.get('dart_sdk_arch', 'x64') == 'x64')
root = pathlib.Path(sys.argv[3])
root.joinpath('url').write_text(manifest['base_url'] + '/' + release['archive'])
root.joinpath('checksum').write_text(release['sha256'] + '  flutter.tar.xz\n')
PY
  curl --fail --silent --show-error --location --retry 2 "$(cat "$download_dir/url")" --output "$download_dir/flutter.tar.xz"
  (cd "$download_dir" && sha256sum --check checksum)
  tar -xJf "$download_dir/flutter.tar.xz" -C "$download_dir"
  if [[ -e "$FW_TOOLS_ROOT/flutter" ]]; then
    echo 'Existing SDK directory must be inspected before replacement.' >&2
    exit 1
  fi
  mv "$download_dir/flutter" "$FW_TOOLS_ROOT/flutter"
fi
flutter --version --machine > "$FW_TOOLS_ROOT/flutter-version.json"
python3 - "$FW_TOOLS_ROOT/flutter-version.json" "$flutter_version" <<'PY'
import json, pathlib, sys
actual = json.loads(pathlib.Path(sys.argv[1]).read_text())['frameworkVersion']
if actual != sys.argv[2]:
    raise SystemExit(f'Expected Flutter {sys.argv[2]}, found {actual}; do not replace an existing SDK automatically.')
PY
flutter config --no-analytics --enable-web
dart --disable-analytics
flutter precache --web --linux
if [[ -f pubspec.lock ]]; then
  flutter pub get --enforce-lockfile
else
  flutter pub get
fi
