//
//  ContentView.swift
//  HiddenWatermarkDemo
//
//  Created by LiYanan2004 on 2023/8/2.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // State
    @State private var platformImage: PlatformImage?
    @State private var dropTargetted = false
    @State private var watermarkContent = ""
    @State private var result: String?
    @State private var showTextField = false
    
    // Progress
    @State private var progress: Double?
    @State private var progressUpdateThreshold = 0.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let platformImage {
                    Rectangle()
                        .overlay {
                            Image(platformImage: platformImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.quaternary)
                        Text("Drag a photo here.").font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.blue, lineWidth: 3.0)
                    .opacity(dropTargetted ? 1 : 0)
            }
            .onDrop(of: [.image], isTargeted: $dropTargetted) { providers in
                _ = providers.first?.loadDataRepresentation(for: .image) { data, _ in
                    guard let data else { return }
                    if let platformImage = PlatformImage(data: data) {
                        self.platformImage = platformImage
                    }
                }
                return true
            }
            .toolbar(content: toolbarContent)
            .safeAreaInset(edge: .bottom) {
                if let progress {
                    ProgressView(value: progress)
                        .transition(.move(edge: .bottom).animation(.easeInOut))
                }
            }
            .scenePadding()
        }
    }
    
    private func addWatermark() {
        Task.detached {
            progressUpdateThreshold = 0.0
            guard let platformImage else { return }
            let wmImage = await Watermarker.markImage(platformImage, text: watermarkContent) { progress in
                guard progress > progressUpdateThreshold else { return }
                progressUpdateThreshold = min(1.0, progress + 0.05)
                self.progress = min(1.0, progress)
            }
            try? await Task.sleep(for: .seconds(1.5)) // Make progress bar able to go to the end.
            defer { self.progress = nil }
            guard let wmImage else { return }
            #if canImport(UIKit)
            self.platformImage = PlatformImage(cgImage: wmImage)
            #elseif canImport(AppKit)
            self.platformImage = PlatformImage(cgImage: wmImage, size: .zero)
            #endif
        }
    }
    
    private func extractWatermark() {
        Task.detached {
            progressUpdateThreshold = 0.0
            guard let platformImage else { return }
            result = await Watermarker.extract(platformImage)
        }
    }
}

// MARK: - Toolbar Contents

extension ContentView {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Group {
                let image = Image(platformImage: platformImage ?? PlatformImage())
                ShareLink(
                    item: image,
                    preview: SharePreview(Text("Photo"), image: image)
                )
                .disabled(platformImage == nil)
            }
            Button {
                showTextField = true
            } label: {
                Label("Watermark", systemImage: "water.waves")
            }
            .disabled(platformImage == nil)
            .popover(isPresented: $showTextField, arrowEdge: .bottom) {
                VStack(spacing: 20) {
                    TextField("Watermark Content", text: $watermarkContent)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    Button {
                        showTextField = false
                        addWatermark()
                    } label: {
                        Text("Add Watermark").padding(4)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .controlSize(.large)
            }
            
            Button(action: extractWatermark) {
                Label("Extract Watermark", systemImage: "water.waves.slash")
            }
            .disabled(platformImage == nil)
            .popover(item: $result) {
                Text($0)
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
