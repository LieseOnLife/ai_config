#!/usr/bin/env swift
// Fetch today's calendar events from named calendars, filtered to:
//   - status != cancelled
//   - availability == busy (Calendar "Show as" = Busy)
//   - if user is an attendee, their participation status == accepted
// Output (one line per event): <title>|<start date>|<calendar name>|<organizer email>|<attendee emails comma-separated, excluding self>

import EventKit
import Foundation

let targetNames: Set<String> = ["saje.liese@datadoghq.com", "Calendar", "Infra Teams"]

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
var authError: Error?

if #available(macOS 14.0, *) {
    store.requestFullAccessToEvents { ok, err in
        granted = ok
        authError = err
        sem.signal()
    }
} else {
    store.requestAccess(to: .event) { ok, err in
        granted = ok
        authError = err
        sem.signal()
    }
}
sem.wait()

guard granted else {
    FileHandle.standardError.write("Calendar access denied: \(authError?.localizedDescription ?? "unknown")\n".data(using: .utf8)!)
    exit(1)
}

let cal = Calendar.current
let start = cal.startOfDay(for: Date())
guard let end = cal.date(byAdding: .day, value: 1, to: start) else { exit(1) }

let calendars = store.calendars(for: .event).filter { targetNames.contains($0.title) }
let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
let events = store.events(matching: predicate)

let formatter = DateFormatter()
formatter.dateStyle = .full
formatter.timeStyle = .medium

for ev in events {
    if ev.status == .canceled { continue }
    if ev.availability != .busy { continue }
    if let attendees = ev.attendees,
       let me = attendees.first(where: { $0.isCurrentUser }),
       me.participantStatus != .accepted {
        continue
    }
    let title = ev.title ?? ""
    let organizerEmail = ev.organizer?.url.absoluteString.replacingOccurrences(of: "mailto:", with: "") ?? ""
    let others = (ev.attendees ?? [])
        .filter { !$0.isCurrentUser }
        .map { $0.url.absoluteString.replacingOccurrences(of: "mailto:", with: "") }
        .joined(separator: ",")
    print("\(title)|\(formatter.string(from: ev.startDate))|\(ev.calendar.title)|\(organizerEmail)|\(others)")
}
