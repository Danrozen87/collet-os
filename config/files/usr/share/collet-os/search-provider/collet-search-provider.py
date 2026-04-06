#!/usr/bin/env python3
"""
Collet OS — GNOME Shell AI Search Provider
Implements org.gnome.Shell.SearchProvider2 over D-Bus.

When you type in GNOME Activities overview, this provider sends your query
to the local Ollama instance and returns a short AI answer as a search result.

Queries shorter than 6 characters are ignored (too vague for AI).
The AI response is cached per-session to avoid redundant API calls.
"""

import dbus
import dbus.service
import dbus.mainloop.glib
import json
import os
import urllib.request
import urllib.error
from gi.repository import GLib

OLLAMA_ENDPOINT = os.environ.get(
    "COLLET_OLLAMA_ENDPOINT", "http://localhost:11434"
)
OLLAMA_MODEL = os.environ.get("COLLET_OLLAMA_MODEL", "collet-assistant")
MIN_QUERY_LENGTH = 6
AI_TIMEOUT = 5  # Short timeout for search provider (Activities expects fast results)

SEARCH_PROVIDER_IFACE = "org.gnome.Shell.SearchProvider2"
BUS_NAME = "org.collet.AISearchProvider"
OBJECT_PATH = "/org/collet/AISearchProvider"

# Cache: query -> response (avoids re-querying while user is typing)
_cache = {}


def query_ollama_sync(query):
    """Synchronous Ollama query with short timeout."""
    if query in _cache:
        return _cache[query]
    try:
        payload = json.dumps({
            "model": OLLAMA_MODEL,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a concise assistant. Answer in one sentence. "
                        "Detect the user's language and respond in it."
                    ),
                },
                {"role": "user", "content": query},
            ],
            "stream": False,
            "options": {"temperature": 0.3, "num_predict": 100},
        }).encode()

        req = urllib.request.Request(
            f"{OLLAMA_ENDPOINT}/api/chat",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=AI_TIMEOUT) as resp:
            data = json.loads(resp.read())
            answer = data.get("message", {}).get("content", "").strip()
            if answer:
                _cache[query] = answer
                # Keep cache bounded
                if len(_cache) > 50:
                    oldest = next(iter(_cache))
                    del _cache[oldest]
                return answer
    except Exception:
        pass
    return ""


class ColletAISearchProvider(dbus.service.Object):
    """D-Bus service implementing org.gnome.Shell.SearchProvider2."""

    def __init__(self):
        bus = dbus.SessionBus()
        bus_name = dbus.service.BusName(BUS_NAME, bus=bus)
        super().__init__(bus_name, OBJECT_PATH)
        self._last_query = ""
        self._last_response = ""

    @dbus.service.method(
        SEARCH_PROVIDER_IFACE,
        in_signature="as",
        out_signature="as",
    )
    def GetInitialResultSet(self, terms):
        query = " ".join(terms)
        if len(query) < MIN_QUERY_LENGTH:
            return []

        response = query_ollama_sync(query)
        if response:
            self._last_query = query
            self._last_response = response
            return ["collet-ai-result"]
        return []

    @dbus.service.method(
        SEARCH_PROVIDER_IFACE,
        in_signature="asas",
        out_signature="as",
    )
    def GetSubsearchResultSet(self, previous_results, terms):
        return self.GetInitialResultSet(terms)

    @dbus.service.method(
        SEARCH_PROVIDER_IFACE,
        in_signature="as",
        out_signature="aa{sv}",
    )
    def GetResultMetas(self, ids):
        metas = []
        if "collet-ai-result" in ids and self._last_response:
            metas.append({
                "id": "collet-ai-result",
                "name": self._last_response[:80],
                "description": f"AI: {self._last_query}",
            })
        return metas

    @dbus.service.method(
        SEARCH_PROVIDER_IFACE,
        in_signature="sas",
        out_signature="",
    )
    def ActivateResult(self, result_id, terms, timestamp=0):
        # Open the full command palette with the query
        query = " ".join(terms) if terms else self._last_query
        os.spawnlp(os.P_NOWAIT, "collet-palette", "collet-palette")

    @dbus.service.method(
        SEARCH_PROVIDER_IFACE,
        in_signature="as",
        out_signature="",
    )
    def LaunchSearch(self, terms, timestamp=0):
        os.spawnlp(os.P_NOWAIT, "collet-palette", "collet-palette")


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    _ = ColletAISearchProvider()
    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    main()
