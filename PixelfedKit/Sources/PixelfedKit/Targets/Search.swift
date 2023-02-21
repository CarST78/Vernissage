//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

extension Pixelfed {
    public enum Search {
        case search(SearchQuery, ResultsType, Bool)
    }
}


extension Pixelfed.Search: TargetType {
    public enum ResultsType: String {
        case accounts = "accounts"
        case hashtags = "hashtags"
        case statuses = "statuses"
    }
    
    fileprivate var apiPath: String { return "/api/v2/search" }

    /// The path to be appended to `baseURL` to form the full `URL`.
    public var path: String {
        switch self {
        case .search:
            return "\(apiPath)"
        }
    }
    
    /// The HTTP method used in the request.
    public var method: Method {
        switch self {
        case .search:
            return .get
        }
    }
    
    /// The parameters to be incoded in the request.
    public var queryItems: [(String, String)]? {
        switch self {
        case .search(let query, let resultsType, let resolveNonLocal):
            return [
                ("q", query),
                ("type", resultsType.rawValue),
                ("resolve", resolveNonLocal.asString)
            ]
        }
    }
    
    public var headers: [String: String]? {
        [:].contentTypeApplicationJson
    }
    
    public var httpBody: Data? {
        nil
    }
}