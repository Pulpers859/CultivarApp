import Foundation

enum WateringSchedule {
    static func normalizedIntervalDays(_ rawInterval: Int) -> Int {
        max(1, rawInterval)
    }

    static func nextWateringDate(
        lastWatered: Date?,
        intervalDays: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        guard let lastWatered else { return now }
        let safeInterval = normalizedIntervalDays(intervalDays)
        return calendar.date(byAdding: .day, value: safeInterval, to: lastWatered)
    }

    static func daysUntilWater(
        lastWatered: Date?,
        intervalDays: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let nextDate = nextWateringDate(
            lastWatered: lastWatered,
            intervalDays: intervalDays,
            now: now,
            calendar: calendar
        ) else {
            return nil
        }
        return calendar.dateComponents([.day], from: now, to: nextDate).day
    }
}
