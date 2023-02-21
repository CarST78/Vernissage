//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI

struct ImagesViewer: View {
    @Environment(\.dismiss) private var dismiss
        
    private let statusViewModel: StatusModel
    private let selectedAttachmentId: String
    private let image: Image
    private let closeDragDistance = UIScreen.main.bounds.height / 1.8
            
    // Magnification.
    @State private var currentMagnification = 0.0
    @State private var finalMagnification = 1.0
    
    // Rotation.
    @State private var rotationAngle = Angle.zero
    
    // Draging.
    @State private var currentOffset = CGSize.zero
    @State private var accumulatedOffset = CGSize.zero
        
    init(statusViewModel: StatusModel, selectedAttachmentId: String) {
        self.statusViewModel = statusViewModel
        self.selectedAttachmentId = selectedAttachmentId
        
        if let attachment = statusViewModel.mediaAttachments.first(where: { $0.id == selectedAttachmentId }),
           let data = attachment.data,
           let uiImage = UIImage(data: data) {
            self.image = Image(uiImage: uiImage)
        } else {
            self.image = Image(systemName: "photo")
        }
    }
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .tag(selectedAttachmentId)
            .offset(currentOffset)
            .rotationEffect(rotationAngle)
            .scaleEffect(finalMagnification + currentMagnification)
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .gesture(doubleTapGesture)
            .gesture(tapGesture)
    }
        
    @MainActor
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { amount in
                self.currentMagnification = (amount - 1) * self.finalMagnification
            }
            .onEnded { amount in
                self.revertToPrecalculatedMagnification()
            }
    }
    
    var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                withAnimation {
                    if self.finalMagnification == 1.0 {
                        self.currentOffset = CGSize.zero
                        self.accumulatedOffset = CGSize.zero
                        self.currentMagnification = 0
                        self.finalMagnification = 2.0
                    } else {
                        self.currentOffset = CGSize.zero
                        self.accumulatedOffset = CGSize.zero
                        self.currentMagnification = 0
                        self.finalMagnification = 1.0
                    }
                }
            }
    }
    
    @MainActor
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { amount in
                // Opacity and rotation is working only when we have small image size.
                if self.finalMagnification == 1.0 {
                    // We can move image whatever we want.
                    self.currentOffset = CGSize(width: amount.translation.width + self.accumulatedOffset.width,
                                                height: amount.translation.height + self.accumulatedOffset.height)
                    
                    // Changing angle.
                    self.rotationAngle = Angle(degrees: Double(self.currentOffset.width / 30))
                } else {
                    // Bigger images we can move only horizontally (we have to include magnifications).
                    let offsetWidth = (amount.predictedEndTranslation.width / self.finalMagnification) + self.accumulatedOffset.width
                    
                    withAnimation(.spring()) {
                        self.currentOffset = CGSize(width: offsetWidth, height: 0)
                    }
                }
            } .onEnded { amount in
                self.accumulatedOffset = CGSize(width: (amount.predictedEndTranslation.width / self.finalMagnification) + self.accumulatedOffset.width,
                                                height: (amount.predictedEndTranslation.height / self.finalMagnification) + self.accumulatedOffset.height)
                
                // Animations only for small images sizes,
                if self.finalMagnification == 1.0 {
                    // When we still are in range visible image then we have to only revert back image to starting position..
                    if self.accumulatedOffset.height > -closeDragDistance && self.accumulatedOffset.height < closeDragDistance {
                        withAnimation(.linear(duration: 0.1)) {
                            self.currentOffset = self.accumulatedOffset
                        }
                        
                        // Revert back image offset.
                        withAnimation(.linear(duration: 0.3).delay(0.1)) {
                            self.currentOffset = CGSize.zero
                            self.accumulatedOffset = CGSize.zero
                            self.rotationAngle = Angle.zero
                        }
                    } else {
                        // Close the screen.
                        withAnimation(.linear(duration: 0.4)) {
                            // We have to set end translations for sure outside the screen.
                            self.currentOffset = CGSize(width: amount.predictedEndTranslation.width * 2, height: amount.predictedEndTranslation.height * 2)
                            self.rotationAngle = Angle(degrees: Double(amount.predictedEndTranslation.width / 30))
                            self.accumulatedOffset = CGSize.zero
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withoutAnimation {
                                self.dismiss()
                            }
                        }
                    }
                } else {
                    self.moveToEdge()
                }
            }
    }
    
    var tapGesture: some Gesture {
        TapGesture().onEnded({ _ in
            withoutAnimation {
                self.dismiss()
            }
        })
    }
    
    @MainActor
    private func revertToPrecalculatedMagnification() {
        let magnification = self.finalMagnification + self.currentMagnification
        
        if magnification < 1.0 {
            // When image is small we are returning to starting point.
            withAnimation {
                self.finalMagnification = 1.0
                self.currentMagnification = 0
                
                // Also we have to move image to orginal position.
                self.currentOffset = CGSize.zero
            }
            
            HapticService.shared.fireHaptic(of: .animation)
        } else if magnification > 3.0 {
            // When image is magnified to much we are rturning to 1.5 maginification.
            withAnimation {
                self.finalMagnification = 3.0
                self.currentMagnification = 0
            }
            
            HapticService.shared.fireHaptic(of: .animation)
        } else {
            self.finalMagnification = magnification
            self.currentMagnification = 0

            // Verify if we have to move image to nearest edge.
            self.moveToEdge()
        }
    }
    
    @MainActor
    private func moveToEdge() {
        let maxEdgeDistance = ((UIScreen.main.bounds.width * self.finalMagnification) - UIScreen.main.bounds.width) / (2 * self.finalMagnification)
        
        if self.currentOffset.width > maxEdgeDistance {
            withAnimation(.linear(duration: 0.15)) {
                self.currentOffset = CGSize(width: maxEdgeDistance, height: 0)
                self.accumulatedOffset = self.currentOffset
            }

            HapticService.shared.fireHaptic(of: .animation)
        } else if self.currentOffset.width < -maxEdgeDistance {
            withAnimation(.linear(duration: 0.15)) {
                self.currentOffset = CGSize(width: -maxEdgeDistance, height: 0)
                self.accumulatedOffset = self.currentOffset
            }
            
            HapticService.shared.fireHaptic(of: .animation)
        }
    }
}
