import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = APIClient.parseDate(raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date \(raw)")
        }
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    private static let fallbackDateFormats = [
        "yyyy-MM-dd'T'HH:mm:ssXXXXX",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
    ]

    private static func parseDate(_ raw: String) -> Date? {
        if let date = dateFormatter.date(from: raw) ?? fractionalDateFormatter.date(from: raw) {
            return date
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in fallbackDateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func ping() async -> Bool {
        do {
            let data = try await sendRaw("GET", path: "health/live", authorized: false)
            return !data.isEmpty
        } catch {
            return false
        }
    }

    func send<Response: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        authorized: Bool = true,
        allowRetry: Bool = true
    ) async throws -> Response {
        let data = try await sendRaw(method, path: path, body: body, authorized: authorized, allowRetry: allowRetry)
        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.message("The server sent data this app could not read.")
        }
    }

    func sendRaw(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        authorized: Bool = true,
        allowRetry: Bool = true
    ) async throws -> Data {
        var request = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        if authorized, let token = AuthSession.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.unreachable
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unreachable
        }
        if http.statusCode == 204 {
            return Data()
        }
        if http.statusCode == 401, authorized, allowRetry, await AuthSession.shared.refreshIfPossible() {
            return try await sendRaw(method, path: path, body: body, authorized: true, allowRetry: false)
        }
        if (200..<300).contains(http.statusCode) {
            return data
        }
        if let body = try? decoder.decode(APIErrorBody.self, from: data) {
            if body.error.code == "conflict" {
                throw APIError.conflict
            }
            throw APIError.message(body.error.message)
        }
        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        throw APIError.message("Request failed (\(http.statusCode)).")
    }
}

struct EmptyResponse: Decodable {}

private struct AnyEncodable: Encodable {
    let value: any Encodable
    init(_ value: any Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
