//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the Apache License 2.0.
//

import SwiftUI
import PixelfedKit
import NukeUI

struct ImageRowItemAsync: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var client: Client
    @EnvironmentObject var routerPath: RouterPath

    private var statusViewModel: StatusModel
    private var attachment: AttachmentModel

    @State private var showThumbImage = false
    @State private var opacity = 0.0

    private let onImageDownloaded: (Double, Double) -> Void

    init(statusViewModel: StatusModel, attachment: AttachmentModel, onImageDownloaded: @escaping (_: Double, _: Double) -> Void) {
        self.statusViewModel = statusViewModel
        self.attachment = attachment
        self.onImageDownloaded = onImageDownloaded
    }

    var body: some View {
        LazyImage(url: attachment.url) { state in
            if let image = state.image {
                if self.statusViewModel.sensitive && !self.applicationState.showSensitive {
                    ZStack {
                        ContentWarning(spoilerText: self.statusViewModel.spoilerText) {
                            self.imageView(image: image)
                        } blurred: {
                            BlurredImage(blurhash: attachment.blurhash)
                                .onTapGesture {
                                    self.navigateToStatus()
                                }
                        }

                        if showThumbImage {
                            FavouriteTouch {
                                self.showThumbImage = false
                            }
                        }
                    }
                    .opacity(self.opacity)
                    .onAppear {
                        if let uiImage = state.imageResponse?.image {
                            self.recalculateSizeOfDownloadedImage(uiImage: uiImage)
                        }

                        withAnimation {
                            self.opacity = 1.0
                        }
                    }
                } else {
                    ZStack {
                        self.imageView(image: image)

                        if showThumbImage {
                            FavouriteTouch {
                                self.showThumbImage = false
                            }
                        }
                    }
                    .opacity(self.opacity)
                    .onAppear {
                        if let uiImage = state.imageResponse?.image {
                            self.recalculateSizeOfDownloadedImage(uiImage: uiImage)
                        }

                        withAnimation {
                            self.opacity = 1.0
                        }
                    }
                }
            } else if state.error != nil {
                ZStack {
                    Rectangle()
                        .fill(Color.placeholderText)
                        .scaledToFill()

                    VStack(alignment: .center) {
                        Spacer()
                        Text("global.error.errorDuringImageDownload", comment: "Cannot download image")
                            .foregroundColor(.systemBackground)
                        Spacer()
                    }
                }
            } else {
                VStack(alignment: .center) {
                    BlurredImage(blurhash: attachment.blurhash)
                        .onTapGesture {
                            self.navigateToStatus()
                        }
                }
            }
        }
        .priority(.high)
    }

    @ViewBuilder
    private func imageView(image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onTapGesture(count: 2) {
                Task {
                    try? await self.client.statuses?.favourite(statusId: self.statusViewModel.id)
                }

                self.showThumbImage = true
                HapticService.shared.fireHaptic(of: .buttonPress)
            }
            .onTapGesture {
                self.navigateToStatus()
            }
            .imageContextMenu(client: self.client, statusModel: self.statusViewModel)
    }

    private func navigateToStatus() {
        self.routerPath.navigate(to: .status(
            id: statusViewModel.id,
            blurhash: statusViewModel.mediaAttachments.first?.blurhash,
            highestImageUrl: statusViewModel.mediaAttachments.getHighestImage()?.url,
            metaImageWidth: statusViewModel.getImageWidth(),
            metaImageHeight: statusViewModel.getImageHeight()
        ))
    }

    private func recalculateSizeOfDownloadedImage(uiImage: UIImage) {
        let size = ImageSizeService.shared.calculate(for: attachment.url,
                                                     width: uiImage.size.width,
                                                     height: uiImage.size.height)

        self.onImageDownloaded(size.width, size.height)
    }
}
