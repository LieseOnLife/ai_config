-- Fetch today's calendar events from named calendars.
-- Output format (one event per line): <title>|<start date string>|<calendar name>
-- Broad iteration (every calendar) silently hangs on Siri Suggestions / Holidays
-- calendars, so we query a curated list of names instead.

set today to current date
set hours of today to 0
set minutes of today to 0
set seconds of today to 0
set tomorrow to today + (1 * days)
set output to ""

tell application "Calendar"
    set targetCals to {"saje.liese@datadoghq.com", "Calendar", "Infra Teams"}
    repeat with calName in targetCals
        try
            tell calendar calName
                set evs to (every event whose start date ≥ today and start date < tomorrow)
                repeat with ev in evs
                    set output to output & (summary of ev) & "|" & (start date of ev as string) & "|" & calName & linefeed
                end repeat
            end tell
        end try
    end repeat
end tell

return output
