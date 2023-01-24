//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import NukeUI

struct UsernameRow: View {
    @State public var accountId: String
    @State public var accountAvatar: URL?
    @State public var accountDisplayName: String?
    @State public var accountUsername: String

    var body: some View {
        HStack (alignment: .center) {
            UserAvatar(accountAvatar: accountAvatar, size: .list)
            
            VStack (alignment: .leading) {
                Text(accountDisplayName ?? accountUsername)
                    .foregroundColor(.mainTextColor)
                Text("@\(accountUsername)")
                    .foregroundColor(.lightGrayColor)
                    .font(.footnote)
            }
            .padding(.leading, 8)
        }
    }
}
