//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import MastodonKit
import AVFoundation

struct StatusView: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var client: Client
    @EnvironmentObject var routerPath: RouterPath

    @Environment(\.dismiss) private var dismiss

    @State var statusId: String
    @State var imageBlurhash: String?
    @State var highestImageUrl: URL?
    @State var imageWidth: Int32?
    @State var imageHeight: Int32?

    @State private var showImageViewer = false
    @State private var state: ViewState = .loading
    
    @State private var statusViewModel: StatusModel?
    
    @State private var selectedAttachmentId: String?
    @State private var exifCamera: String?
    @State private var exifExposure: String?
    @State private var exifCreatedDate: String?
    @State private var exifLens: String?
        
    var body: some View {
        self.mainBody()
            .navigationBarTitle("Details")
            .fullScreenCover(isPresented: $showImageViewer, content: {
                if let statusViewModel = self.statusViewModel {
                    ImagesViewer(statusViewModel: statusViewModel, selectedAttachmentId: selectedAttachmentId ?? String.empty())
                }
            })
    }
    
    @ViewBuilder
    private func mainBody() -> some View {
        switch state {
        case .loading:
            StatusPlaceholder(imageHeight: self.getImageHeight(), imageBlurhash: self.imageBlurhash)
                .task {
                    await self.loadData()
                }
        case .loaded:
            if let statusViewModel = self.statusViewModel {
                ScrollView {
                    VStack (alignment: .leading) {
                        ImagesCarousel(attachments: statusViewModel.mediaAttachments,
                                       selectedAttachmentId: $selectedAttachmentId,
                                       exifCamera: $exifCamera,
                                       exifExposure: $exifExposure,
                                       exifCreatedDate: $exifCreatedDate,
                                       exifLens: $exifLens)
                        .onTapGesture {
                            withoutAnimation {
                                self.showImageViewer.toggle()
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            self.reblogInformation()

                            UsernameRow(accountId: statusViewModel.account.id,
                                        accountAvatar: statusViewModel.account.avatar,
                                        accountDisplayName: statusViewModel.account.displayNameWithoutEmojis,
                                        accountUsername: statusViewModel.account.acct)
                            .onTapGesture {
                                self.routerPath.navigate(to: .userProfile(accountId: statusViewModel.account.id,
                                                                          accountDisplayName: statusViewModel.account.displayNameWithoutEmojis,
                                                                          accountUserName: statusViewModel.account.acct))
                            }
                            
                            MarkdownFormattedText(statusViewModel.content.asMarkdown)
                                .environment(\.openURL, OpenURLAction { url in
                                    routerPath.handle(url: url)
                                })

                            VStack (alignment: .leading) {
                                if let name = statusViewModel.place?.name, let country = statusViewModel.place?.country {
                                    LabelIcon(iconName: "mappin.and.ellipse", value: "\(name), \(country)")
                                }
                                
                                LabelIcon(iconName: "camera", value: self.exifCamera)
                                LabelIcon(iconName: "camera.aperture", value: self.exifLens)
                                LabelIcon(iconName: "timelapse", value: self.exifExposure)
                                LabelIcon(iconName: "calendar", value: self.exifCreatedDate?.toDate(.isoDateTimeSec)?.formatted())
                            }
                            .padding(.bottom, 2)
                            .foregroundColor(.lightGrayColor)
                            
                            HStack {
                                Text("Uploaded")
                                Text(statusViewModel.createdAt.toRelative(.isoDateTimeMilliSec))
                                    .padding(.horizontal, -4)
                                if let applicationName = statusViewModel.application?.name {
                                    Text("via \(applicationName)")
                                }
                            }
                            .foregroundColor(.lightGrayColor)
                            .font(.footnote)
                            
                            InteractionRow(statusViewModel: statusViewModel)
                                .foregroundColor(.accentColor)
                                .padding(8)
                        }
                        .padding(8)
                                            
                        CommentsSection(statusId: statusViewModel.id)
                    }
                }
            }

        case .error(let error):
            ErrorView(error: error) {
                self.state = .loading
                await self.loadData()
            }
            .padding()
        }
    }
    
    @ViewBuilder func reblogInformation() -> some View {
        if let reblogStatus = self.statusViewModel?.reblogStatus {
            HStack(alignment: .center, spacing: 4) {
                UserAvatar(accountAvatar: reblogStatus.account.avatar, size: .mini)
                Text(reblogStatus.account.displayNameWithoutEmojis)
                Image(systemName: "paperplane")
                    .padding(.trailing, 8)
            }
            .font(.footnote)
            .foregroundColor(Color.mainTextColor.opacity(0.4))
            .background(Color.mainTextColor.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private func loadData() async {
        do {
            // Get status from API.
            if let status = try await self.client.statuses?.status(withId: self.statusId) {
                let statusViewModel = StatusModel(status: status)
                                    
                self.statusViewModel = statusViewModel
                self.selectedAttachmentId = statusViewModel.mediaAttachments.first?.id ?? String.empty()
                
                // If we have status in database then we can update data.
                if let accountData = self.applicationState.account,
                   let statusDataFromDatabase = StatusDataHandler.shared.getStatusData(accountId: accountData.id, statusId: self.statusId) {
                    _ = try await HomeTimelineService.shared.update(status: statusDataFromDatabase, basedOn: status, for: accountData)
                }
            }
            
            self.state = .loaded
        } catch NetworkError.notSuccessResponse(let response) {
            if response.statusCode() == HTTPStatusCode.notFound, let accountId = self.applicationState.account?.id {
                StatusDataHandler.shared.remove(accountId: accountId, statusId: self.statusId)
                ErrorService.shared.handle(NetworkError.notSuccessResponse(response), message: "Status not existing anymore.", showToastr: true)
                dismiss()
            }
        }
        catch {
            if !Task.isCancelled {
                ErrorService.shared.handle(error, message: "Error during download status from server.", showToastr: true)
                self.state = .loaded
            } else {
                ErrorService.shared.handle(error, message: "Error during download status from server.", showToastr: false)
            }
        }
    }
    
    private func setAttachment(_ attachmentData: AttachmentData) {
        exifCamera = attachmentData.exifCamera
        exifExposure = attachmentData.exifExposure
        exifCreatedDate = attachmentData.exifCreatedDate
        exifLens = attachmentData.exifLens
    }
    
    private func getImageHeight() -> Double {
        if let highestImageUrl = self.highestImageUrl, let imageSize = ImageSizeService.shared.get(for: highestImageUrl) {
            return imageSize.height
        }
        
        if let imageHeight = self.imageHeight, let imageWidth = self.imageWidth, imageHeight > 0 && imageWidth > 0 {
            return self.calculateHeight(width: Double(imageWidth), height: Double(imageHeight))
        }
        
        // If we don't have image height and width in metadata, we have to use some constant height.
        return UIScreen.main.bounds.width * 0.75
    }
    
    private func calculateHeight(width: Double, height: Double) -> CGFloat {
        let divider = width / UIScreen.main.bounds.size.width
        return height / divider
    }
}

