import Foundation

enum ParsingUtils {
    static func parseLocalizedDecimal(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let direct = Double(trimmed) {
            return direct
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: trimmed)?.doubleValue
    }
}
