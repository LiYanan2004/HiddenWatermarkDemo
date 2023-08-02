//
//  PlatformImage+SwiftUI.swift
//  HiddenWatermarkDemo
//
//  Created by LiYanan2004 on 2023/8/2.
//

import SwiftUI

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
