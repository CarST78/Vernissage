//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    

import Foundation
import MastodonSwift

extension AttachmentData {
    func copyFrom(_ attachment: Attachment) {
        self.id = attachment.id
        self.url = attachment.url
        self.blurhash = attachment.blurhash
        self.previewUrl = attachment.previewUrl
        self.remoteUrl = attachment.remoteUrl
        self.text = attachment.description
        self.type = attachment.type.rawValue
    }
}
