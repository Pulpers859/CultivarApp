import Foundation

enum Config {
    static let bundledAnthropicAPIKey = ""

    static var anthropicAPIKey: String {
        APIKeyProvider.anthropicKey ?? bundledAnthropicAPIKey
    }

    static var hasAnthropicKey: Bool {
        !anthropicAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static let claudeModel = "claude-sonnet-4-20250514"
}

enum APIKeyProvider {
    private static let envKey = "ANTHROPIC_API_KEY"
    private static let plistKey = "ANTHROPIC_API_KEY"

    static var anthropicKey: String? {
        if let env = ProcessInfo.processInfo.environment[envKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            return env
        }

        if let plistValue = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String {
            let cleaned = plistValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                return cleaned
            }
        }

        return nil
    }
}
