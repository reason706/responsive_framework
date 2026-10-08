# Source this file from the repository root before using Flutter or Dart.
export FW_TOOLS_ROOT="${FW_TOOLS_ROOT:-/workspace/.fw-tools}"
export PUB_CACHE="$FW_TOOLS_ROOT/pub-cache"
export XDG_CONFIG_HOME="$FW_TOOLS_ROOT/config"
export XDG_CACHE_HOME="$FW_TOOLS_ROOT/cache"
export ANALYZER_STATE_LOCATION_OVERRIDE="$FW_TOOLS_ROOT/analyzer"
# Dart recognizes CI as a supported way to suppress analytics initialization.
# Keep tool invocations noninteractive and avoid writes to a read-only home.
export CI="${CI:-true}"
export FLUTTER_SUPPRESS_ANALYTICS=true
export PATH="$FW_TOOLS_ROOT/flutter/bin:$PATH"
