// NotificationService.swift

import UserNotifications
import SwiftData
import Foundation
import UIKit

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Schedule Watering Reminder
    func scheduleWateringReminder(for plant: Plant) {
        let intervalDays = WateringSchedule.normalizedIntervalDays(plant.wateringIntervalDays)
        guard let nextDate = WateringSchedule.nextWateringDate(
            lastWatered: plant.lastWatered,
            intervalDays: intervalDays
        ) else { return }
        let center = UNUserNotificationCenter.current()

        // Cancel existing reminder for this plant
        center.removePendingNotificationRequests(withIdentifiers: [wateringID(for: plant)])

        let content = UNMutableNotificationContent()
        content.title = "\(plant.emoji) \(plant.nickname) is thirsty"
        content.body = "Time to water your \(plant.commonName.isEmpty ? "plant" : plant.commonName). Check the soil first!"
        content.sound = .default
        content.badge = 1

        // Schedule for 8am on the due date and move forward if that timestamp is already in the past.
        var components = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
        components.hour = 8
        components.minute = 0
        guard let initialFireDate = Calendar.current.date(from: components) else { return }
        let fireDate = initialFireDate > Date()
            ? initialFireDate
            : Calendar.current.date(byAdding: .day, value: intervalDays, to: initialFireDate) ?? initialFireDate
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: wateringID(for: plant),
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Schedule All Plant Reminders
    func scheduleAllReminders(plants: [Plant]) {
        // Reset to avoid stale reminders for deleted plants.
        cancelAllReminders()
        plants.forEach { scheduleWateringReminder(for: $0) }
    }

    // MARK: - Cancel Reminders
    func cancelReminders(for plant: Plant) {
        let identifier = wateringID(for: plant)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func cancelAllReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func clearDeliveredReminders() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // MARK: - Helpers
    private func wateringID(for plant: Plant) -> String {
        "watering-\(plant.id.uuidString)"
    }
}
