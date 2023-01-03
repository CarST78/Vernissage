//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

extension StatusData {
    func attachments() -> [AttachmentData] {
        return self.attachmentRelation?.sorted(by: <) ?? []
    }
}
