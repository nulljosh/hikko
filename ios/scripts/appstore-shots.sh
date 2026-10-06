#!/bin/bash
# App Store screenshots for one simulator, driven with simctl and AXe.
# No XCUITest involved, so nothing hangs waiting for the app to go idle.
#
#   scripts/appstore-shots.sh <simulator-udid> <out-dir> <path/to/Spark.app>
#
# Build a Debug app for the simulator first (xcodebuild ... -sdk iphonesimulator
# -derivedDataPath X build) and pass X/Build/Products/Debug-iphonesimulator/Spark.app.
# UITEST_SNAPSHOT signs in a mock user so no real account is touched. The feed is the
# live feed. Nothing is voted on or posted, so the mock token is never sent anywhere
# that would reject it.
set -euo pipefail

U=${1:?simulator udid}
OUT=${2:?output dir}
APP=${3:?path to Spark.app}
BID=com.heyitsmejosh.spark

mkdir -p "$OUT"
xcrun simctl bootstatus "$U" -b >/dev/null
xcrun simctl status_bar "$U" override --time 9:41 --batteryState charged \
    --batteryLevel 100 --wifiBars 3 --cellularBars 4
xcrun simctl uninstall "$U" "$BID" 2>/dev/null || true
xcrun simctl install "$U" "$APP"

launch() { # tab: 0 feed, 1 create, 2 profile, 3 ideas
    xcrun simctl terminate "$U" "$BID" 2>/dev/null || true
    SIMCTL_CHILD_UITEST_TAB=$1 xcrun simctl launch "$U" "$BID" UITEST_SNAPSHOT >/dev/null
}
shot() { xcrun simctl io "$U" screenshot --type=png "$OUT/$1.png" >/dev/null 2>&1; }
tap_label() { axe tap --label "$1" --udid "$U" --wait-timeout "${2:-6}" >/dev/null 2>&1 || true; }

# Center of the first feed card, in points.
first_card() {
    axe describe-ui --udid "$U" | python3 -c '
import json, sys
def walk(n):
    if isinstance(n, list):
        for x in n:
            yield from walk(x)
    elif isinstance(n, dict):
        yield n
        yield from walk(n.get("children", []))
for n in walk(json.load(sys.stdin)):
    if n.get("type") == "Button" and " votes, " in (n.get("AXLabel") or ""):
        f = n["frame"]
        print(int(f["x"] + f["width"] / 2), int(f["y"] + min(f["height"], 120) / 2))
        break
'
}

# Screen size in points, from the root element, so swipes fit iPhone and iPad.
screen_size() {
    axe describe-ui --udid "$U" | python3 -c '
import json, sys
f = json.load(sys.stdin)[0]["frame"]
print(int(f["width"]), int(f["height"]))
'
}

# First launch on a fresh install: notification prompt, then the What's New sheet.
launch 0
sleep 4
tap_label "Allow" 8
sleep 3
tap_label "Got it" 8
sleep 3

shot 01-feed

read -r X Y <<<"$(first_card)"
axe tap -x "$X" -y "$Y" --udid "$U" >/dev/null
sleep 4
shot 02-idea

launch 0
sleep 5
tap_label "Technology"
sleep 2
shot 03-feed-filtered

launch 1
sleep 4
shot 04-create

launch 3
sleep 5
shot 05-ideas

# Same tab, scrolled to the topic form at the bottom.
read -r W H <<<"$(screen_size)"
for _ in 1 2 3; do
    axe swipe --start-x $((W / 2)) --start-y $((H * 3 / 4)) --end-x $((W / 2)) --end-y $((H / 6)) \
        --udid "$U" >/dev/null
    sleep 1
done
sleep 1
shot 05b-ideas-generate

launch 2
sleep 4
shot 06-profile

xcrun simctl terminate "$U" "$BID" 2>/dev/null || true
echo "done: $OUT"
