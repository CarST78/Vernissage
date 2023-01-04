//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI

struct InteractionRow: View {
    @ObservedObject public var statusData: StatusData

    var body: some View {
        HStack (alignment: .top) {
            Button {
                // Reply
            } label: {
                HStack(alignment: .center) {
                    Image(systemName: "message")
                    Text("\(statusData.repliesCount)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button {
                // Reboost
            } label: {
                HStack(alignment: .center) {
                    Image(systemName: statusData.reblogged ? "arrowshape.turn.up.forward.fill" : "arrowshape.turn.up.forward")
                    Text("\(statusData.reblogsCount)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button {
                // Favorite
            } label: {
                HStack(alignment: .center) {
                    Image(systemName: statusData.favourited ? "hand.thumbsup.fill" : "hand.thumbsup")
                    Text("\(statusData.favouritesCount)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button {
                // Bookmark
            } label: {
                Image(systemName: statusData.bookmarked ? "bookmark.fill" : "bookmark")
            }
            
            Spacer()
            
            Button {
                // Share
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundColor(Color.accentColor)
    }
}

struct InteractionRow_Previews: PreviewProvider {
    static var previews: some View {
        InteractionRow(statusData: StatusData())
    }
}
