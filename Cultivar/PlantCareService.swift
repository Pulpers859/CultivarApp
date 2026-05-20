import Foundation

@MainActor
enum PlantCareService {
    static func recordCare(
        for plant: Plant,
        careType: CareType,
        notes: String = "",
        soilMoisture: SoilMoisture? = nil,
        fertiliserUsed: String? = nil,
        amountMl: Double? = nil,
        photoData: Data? = nil,
        at date: Date = Date()
    ) {
        let log = CareLog(
            careType: careType,
            notes: notes,
            soilMoisture: careType == .watering ? soilMoisture : nil
        )
        log.date = date
        log.amountMl = amountMl
        log.photoData = photoData

        if careType == .fertilizing {
            let trimmedFertiliser = fertiliserUsed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            log.fertiliserUsed = trimmedFertiliser.isEmpty ? nil : trimmedFertiliser
        }

        plant.careLogs.append(log)
        plant.refreshTrackedCareDates()

        if careType == .watering {
            NotificationService.shared.cancelReminders(for: plant)
            NotificationService.shared.scheduleWateringReminder(for: plant)
        }
    }
}
