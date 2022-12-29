//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    

import SwiftUI

struct LabelIconView: View {
    let iconName: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .frame(width: 36)
            Text(value)
                .font(.footnote)
        }
        .padding(.vertical, 4)
    }
}

struct LabelIconView_Previews: PreviewProvider {
    static var previews: some View {
        LabelIconView(iconName: "camera", value: "Sony A7")
    }
}
