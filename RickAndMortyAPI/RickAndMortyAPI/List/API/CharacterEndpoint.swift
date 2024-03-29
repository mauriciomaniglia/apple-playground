import Foundation

public enum CharacterEndpoint {
    case get(page: Int = 1)

    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(page):
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + "/api/character"
            components.queryItems = [
                URLQueryItem(name: "page", value: "\(page)")
            ].compactMap { $0 }
            return components.url!
        }
    }
}
