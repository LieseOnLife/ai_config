---
name: slack-sidebar-sections
description: "Read Saje's Slack sidebar sections and their channel IDs from the Slack desktop IndexedDB cache (macOS), e.g. to refresh the morning-routine channel lists."
---

# Slack sidebar sections from local cache

The Slack MCP cannot list sidebar sections. The desktop app caches them locally.

1. Make the cache fresh. Slack only rewrites it on its own schedule, so restart it first (Saje has approved this before):
   `osascript -e 'quit app "Slack"' && sleep 8 && open -a Slack && sleep 60`
2. Take the newest file under `~/Library/Application Support/Slack/IndexedDB/https_app.slack.com_0.indexeddb.blob/*/*/*`. Decompress it with `snappy.uncompress(raw[3:])` (`pip install python-snappy`). Skip the first 3 header bytes.
3. Parse the decompressed bytes. They are V8-serialized and the strings are length-prefixed:
   - Section definitions: after the last `channelSectionById`, regex `"\x02id"\x0b(L[A-Z0-9]{10})"\x04type"(.)(.*?)"\x04name"(.)(.*?)"\x05emoji` (the name is `name[:len_byte]`). The order matches the sidebar.
   - Membership: the block after `channelIdsByChannelSectionId`, up to `channelSectionIdsByChannelId`. Split on `"\x0b(L[A-Z0-9]{10})`, then collect `"[\x09-\x0c]([CGD][A-Z0-9]{8,11})` in each piece.
   - Channel names: `"\x02id"[\x09-\x0b]([CG]...)"\x04name"(.)` followed by the name bytes.
4. IDs that start with `D` are DMs. `C` IDs with no cached name are usually group DMs; check with `slack_read_channel` (the channel shows as `Group`). Both belong in the DMs section of the morning routine, not in a channel section.
5. Slack's built-in `stars` section (type `stars`) is never cached with members. Saje uses a custom section named **Starred** instead.

Never extract Slack session tokens.
