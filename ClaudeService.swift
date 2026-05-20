import Foundation

// MARK: - Anthropic Client (shared networking with retry)

final class AnthropicClient {
    static let shared = AnthropicClient()
    private init() {}

    func sendRequest(body: [String: Any], timeout: TimeInterval = 30) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw ClaudeError.invalidURL
        }

        let apiKey = Config.anthropicAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw ClaudeError.missingAPIKey
        }

        let encodedBody = try JSONSerialization.data(withJSONObject: body)
        let maxAttempts = 2

        for attempt in 1...maxAttempts {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                request.httpBody = encodedBody
                request.timeoutInterval = timeout

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ClaudeError.invalidResponse
                }

                if httpResponse.statusCode == 200 {
                    let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
                    let text = apiResponse.content
                        .compactMap { $0.text }
                        .joined()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else {
                        throw ClaudeError.invalidResponse
                    }
                    return text
                }

                if shouldRetry(statusCode: httpResponse.statusCode), attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    continue
                }

                if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJSON["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: message)
                }
                throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: nil)
            } catch let error as ClaudeError {
                throw error
            } catch {
                if shouldRetry(error: error), attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    continue
                }
                throw error
            }
        }

        throw ClaudeError.invalidResponse
    }

    private func shouldRetry(statusCode: Int) -> Bool {
        statusCode == 408 || statusCode == 429 || (500...599).contains(statusCode)
    }

    private func shouldRetry(error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Response Models

struct ClaudeAPIResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let type: String
    let text: String?
}

// MARK: - Public API Functions

func callClaudeAPI(systemPrompt: String, userMessage: String) async throws -> String {
    try await callClaudeAPI(systemPrompt: systemPrompt, userMessage: userMessage, imageData: nil)
}

func callClaudeAPI(systemPrompt: String, userMessage: String, imageData: Data?) async throws -> String {
    var contentArray: [[String: Any]] = []

    if let imageData {
        contentArray.append([
            "type": "image",
            "source": [
                "type": "base64",
                "media_type": inferredMediaType(for: imageData),
                "data": imageData.base64EncodedString()
            ]
        ])
    }

    contentArray.append([
        "type": "text",
        "text": userMessage
    ])

    let body: [String: Any] = [
        "model": Config.claudeModel,
        "max_tokens": 1024,
        "system": systemPrompt,
        "messages": [
            [
                "role": "user",
                "content": contentArray
            ]
        ]
    ]

    return try await AnthropicClient.shared.sendRequest(body: body)
}

private func inferredMediaType(for data: Data) -> String {
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
    if data.starts(with: [0x47, 0x49, 0x46]) { return "image/gif" }
    if data.starts(with: [0x52, 0x49, 0x46, 0x46]) { return "image/webp" }
    return "image/jpeg"
}

// MARK: - Error Type

enum ClaudeError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not set. Add your key to Config.swift or set ANTHROPIC_API_KEY in your environment."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let code, let message):
            if let message, !message.isEmpty {
                return "API error (status \(code)): \(message)"
            }
            return "API error (status \(code)). Check your API key and try again."
        }
    }
}
