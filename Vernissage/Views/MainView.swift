//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import UIKit
import CoreData
import MastodonSwift

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var applicationState: ApplicationState

    @State private var navBarTitle: String = "Home"
    @State private var viewMode: ViewMode = .home {
        didSet {
            self.navBarTitle = self.getViewTitle(viewMode: viewMode)
        }
    }
    
    private enum ViewMode {
        case home, local, federated, notifications
    }
    
    var body: some View {
        self.getMainView()
        .navigationBarTitle(navBarTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            self.getLeadingToolbar()
            self.getPrincipalToolbar()
        }
    }
    
    @ViewBuilder
    private func getMainView() -> some View {
        switch self.viewMode {
        case .home:
            HomeFeedView()
        case .local:
            LocalFeedView()
        case .federated:
            FederatedFeedView()
        case .notifications:
            NotificationsView()
        }
    }
    
    @ToolbarContentBuilder
    private func getPrincipalToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                Button {
                    viewMode = .home
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .home))
                        Image(systemName: "house")
                    }
                }
                
                Button {
                    viewMode = .local
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .local))
                        Image(systemName: "text.redaction")
                    }
                }

                Button {
                    viewMode = .federated
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .federated))
                        Image(systemName: "globe.europe.africa")
                    }
                }
                
                Divider()
                
                Button {
                    viewMode = .notifications
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .notifications))
                        Image(systemName: "bell.badge")
                    }
                }
            } label: {
                HStack {
                    Text(navBarTitle)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                }
                .frame(width: 150)
                .foregroundColor(Color("MainTextColor"))
            }
        }
    }
    
    @ToolbarContentBuilder
    private func getLeadingToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                
                Button {
                    // Switch accounts...
                } label: {
                    HStack {
                        Text(self.applicationState.accountData?.displayName ?? self.applicationState.accountData?.username ?? "")
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(Color("MainTextColor"))
                    }
                }

                Divider()
                
                Button {
                    // Open settings...
                } label: {
                    HStack {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                }
            } label: {
                if let avatarData = self.applicationState.accountData?.avatarData, let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 32.0, height: 32.0)
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 32.0, height: 32.0)
                        .foregroundColor(Color("MainTextColor"))
                }
            }
        }
    }
    
    private func getViewTitle(viewMode: ViewMode) -> String {
        switch viewMode {
        case .home:
            return "Home"
        case .local:
            return "Local"
        case .federated:
            return "Federated"
        case .notifications:
            return "Notifications"
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, CoreDataHandler.preview.container.viewContext)
    }
}
