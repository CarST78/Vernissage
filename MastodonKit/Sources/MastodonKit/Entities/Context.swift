//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

public struct Context: Codable {
    public let ancestors: [Status]
    public let descendants: [Status]

    public enum CodingKeys: CodingKey {
        case ancestors
        case descendants
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ancestors = try container.decode([Status].self, forKey: .ancestors)
        self.descendants = try container.decode([Status].self, forKey: .descendants)
    }
}
