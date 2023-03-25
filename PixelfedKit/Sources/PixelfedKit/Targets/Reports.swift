//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

extension Pixelfed {
    public enum Reports {
        case list
        case report(String, [String], String)
    }
}

extension Pixelfed.Reports: TargetType {
    private struct Request: Encodable {
        let accountId: String
        let statusIds: [String]
        let comment: String
        
        private enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case statusIds = "status_ids"
            case comment
        }
        
        func encode(to encoder: Encoder) throws {
            var container: KeyedEncodingContainer<Pixelfed.Reports.Request.CodingKeys> = encoder.container(keyedBy: Pixelfed.Reports.Request.CodingKeys.self)
            try container.encode(self.accountId, forKey: Pixelfed.Reports.Request.CodingKeys.accountId)
            try container.encode(self.statusIds, forKey: Pixelfed.Reports.Request.CodingKeys.statusIds)
            try container.encode(self.comment, forKey: Pixelfed.Reports.Request.CodingKeys.comment)
        }
    }
    
    private var apiPath: String { return "/api/v1/reports" }

    /// The path to be appended to `baseURL` to form the full `URL`.
    public var path: String {
        switch self {
        case .list, .report(_, _, _):
            return "\(apiPath)"
        }
    }
    
    /// The HTTP method used in the request.
    public var method: Method {
        switch self {
        case .list:
            return .get
        case .report(_, _, _):
            return .post
        }
    }
    
    /// The parameters to be incoded in the request.
    public var queryItems: [(String, String)]? {
        nil
    }
    
    public var headers: [String: String]? {
        [:].contentTypeApplicationJson
    }
    
    public var httpBody: Data? {
        switch self {
        case .list:
            return nil
        case .report(let accountId, let statusIds, let comment):
            return try? JSONEncoder().encode(
                Request(accountId: accountId, statusIds: statusIds, comment: comment)
            )
        }
    }
}
