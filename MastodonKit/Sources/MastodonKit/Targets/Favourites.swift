//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

extension Mastodon {
    public enum Favourites {
        case favourites
    }
}

extension Mastodon.Favourites: TargetType {
    fileprivate var apiPath: String { return "/api/v1/favourites" }

    /// The path to be appended to `baseURL` to form the full `URL`.
    public var path: String {
        switch self {
        case .favourites:
            return "\(apiPath)"
        }
    }
    
    /// The HTTP method used in the request.
    public var method: Method {
        switch self {
        case .favourites:
            return .get
        }
    }
    
    /// The parameters to be incoded in the request.
    public var queryItems: [(String, String)]? {
        switch self {
        case .favourites:
            return nil
        }
    }
    
    public var headers: [String: String]? {
        [:].contentTypeApplicationJson
    }
    
    public var httpBody: Data? {
        nil
    }
}
