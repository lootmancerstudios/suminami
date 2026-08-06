"""Definition loading for SumiNami web apps.

A web app is a Firefox instance with its own profile and window class, given a
tray icon and a launcher so it behaves like an installed application. Each one
is described by a definition file in webapps/<name>.conf.

Mirrors lib/webapp.sh field for field; the two must stay in step. Definitions
are parsed rather than executed, so a stray line in a config file is a bad value
and never runnable code.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(os.environ.get(
    "WEBAPP_ROOT",
    Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "suminami",
))
DEFS_DIR = ROOT / "webapps"
ASSETS_DIR = ROOT / "assets" / "webapps"

# Icon names are prefixed in the shared hicolor theme so a web app cannot
# collide with an icon shipped by a real package.
ICON_PREFIX = "suminami-"


def profile_root() -> Path:
    """Directory Firefox keeps its profiles in on this machine.

    Firefox uses ~/.mozilla/firefox when that directory exists, and the XDG
    location otherwise. This mirrors that rule exactly and MUST never create
    the legacy directory: bringing ~/.mozilla/firefox into existence silently
    switches Firefox out of XDG mode, so it stops seeing an existing profile
    and starts a blank one -- the user's bookmarks appear to vanish.
    """
    legacy = Path.home() / ".mozilla" / "firefox"
    if legacy.is_dir():
        return legacy
    base = Path(os.environ.get("XDG_CONFIG_HOME") or (Path.home() / ".config"))
    return base / "mozilla" / "firefox"

_FIELDS = {
    "name", "class", "url", "icon", "color", "unread_pattern", "app_chrome",
    "key", "user_agent", "window_size", "zoom", "hide_selectors", "notifications", "permissions",
}
_TRUE = {"true", "yes", "on", "1"}


class DefinitionError(Exception):
    """A definition is missing or unusable."""


@dataclass(frozen=True)
class WebApp:
    app: str
    name: str
    wm_class: str
    url: str
    icon: str
    color: str
    unread_pattern: str | None
    app_chrome: bool
    key: str | None
    user_agent: str | None
    window_size: str | None
    zoom: int | None
    hide_selectors: str | None
    notifications: str | None
    permissions: str | None

    @property
    def profile_dir(self) -> Path:
        return profile_root() / self.app

    @property
    def stash_workspace(self) -> str:
        return f"special:{self.wm_class}-hidden"

    @property
    def icon_name(self) -> str:
        return f"{ICON_PREFIX}{self.icon}"

    def unread_icon_name(self, count: int) -> str:
        """Icon showing a count badge, saturating past the pre-rendered maximum.

        Counts up to MAX_BADGE render as themselves; only what exceeds it falls
        back to the "N+" icon. Nine unread reads "9", not "9+".
        """
        if count > MAX_BADGE:
            return f"{self.icon_name}-unread-{MAX_BADGE}-plus"
        return f"{self.icon_name}-unread-{count}"

    def unread_regex(self) -> re.Pattern[str] | None:
        if not self.unread_pattern:
            return None
        try:
            return re.compile(self.unread_pattern)
        except re.error:
            return None


# Highest count drawn as itself. Anything larger shares one "N+" icon, so an
# install stays a fixed number of files however busy a chat gets.
MAX_BADGE = 9


def _parse(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        # Whole-line comments only: values legitimately contain '#', since
        # colours are hex and unread patterns are regexes.
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, _, value = stripped.partition("=")
        key = key.strip()
        if key in _FIELDS:
            values[key] = value.strip()
    return values


def _int_or_none(raw: str | None) -> int | None:
    try:
        return int(raw) if raw else None
    except ValueError:
        return None


def load(app: str) -> WebApp:
    path = DEFS_DIR / f"{app}.conf"
    if not path.is_file():
        raise DefinitionError(f"no definition for {app!r} in {DEFS_DIR}")

    values = _parse(path)
    missing = [f for f in ("class", "url", "icon") if not values.get(f)]
    if missing:
        raise DefinitionError(f"{path} is missing required field(s): {', '.join(missing)}")

    return WebApp(
        app=app,
        name=values.get("name") or app,
        wm_class=values["class"],
        url=values["url"],
        icon=values["icon"],
        color=values.get("color") or "#000000",
        unread_pattern=values.get("unread_pattern") or None,
        app_chrome=values.get("app_chrome", "").lower() in _TRUE,
        key=values.get("key") or None,
        user_agent=values.get("user_agent") or None,
        window_size=values.get("window_size") or None,
        zoom=_int_or_none(values.get("zoom")),
        hide_selectors=values.get("hide_selectors") or None,
        notifications=(values.get("notifications") or "").lower() or None,
        permissions=values.get("permissions") or None,
    )


def available() -> list[str]:
    if not DEFS_DIR.is_dir():
        return []
    return sorted(p.stem for p in DEFS_DIR.glob("*.conf"))
