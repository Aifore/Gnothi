import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
#if os(iOS)
import Photos
import UIKit
#else
import AppKit
#endif

// MARK: - App info（分享图上的品牌信息）

enum AppInfo {
    static let name = "Gnothi"
    static let chineseName = "认识自己"
    static let slogan = "记录每一次与自己的重逢"
    static let downloadHint = "App Store 搜索「Gnothi」"
    // TODO: 上架后替换成真实的 App Store 链接（二维码内容）
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    // TODO: 替换成你的隐私政策页面
    static let privacyURL = URL(string: "https://example.com/gnothi/privacy")!
}

/// 应用小图标（与 App 图标同款插画）
struct AppMark: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                Rectangle().fill(Color(hex: 0xFBF7F1)).place(50, 50, 100, 100)
                Blob(seed: 4, points: 8, variance: 0.1).fill(Color(hex: 0xFBE3D6)).place(50, 50, 82, 78)
                Circle().fill(Theme.butter).place(70, 30, 22, 22)
                Hill(peak: 0.3).fill(Theme.sage).place(50, 90, 100, 30)
                Sprout().place(48, 56, 34, 48)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

enum QRCode {
    static func image(for string: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }
}

enum ImageSaveResult {
    case saved(String)
    case cancelled
    case failed(String)
}

enum ImageSaver {
    #if os(iOS)
    static let actionTitle = "保存到相册"
    static let actionIcon = "square.and.arrow.down"

    /// iPhone：保存到系统相册
    static func save(_ image: CGImage, suggestedName: String) async -> ImageSaveResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return .failed("没有相册权限。请在「设置 › Gnothi › 照片」中允许添加照片。")
        }
        let uiImage = UIImage(cgImage: image, scale: 3, orientation: .up)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }
            return .saved("已保存到相册 🌱")
        } catch {
            return .failed("保存失败：\(error.localizedDescription)")
        }
    }
    #else
    static let actionTitle = "保存为图片…"
    static let actionIcon = "square.and.arrow.down"

    /// Mac：弹出保存面板，写入 PNG
    @MainActor
    static func save(_ image: CGImage, suggestedName: String) async -> ImageSaveResult {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = suggestedName + ".png"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return .cancelled }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            return .failed("生成图片失败，请重试。")
        }
        do {
            try data.write(to: url)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return .saved("图片已保存 🌱")
        } catch {
            return .failed("保存失败：\(error.localizedDescription)")
        }
    }
    #endif
}

// MARK: - Report card（导出为图片的版式，固定宽度 375pt，@3x 渲染）

struct ReportCardView: View {
    let record: TestRecord
    let test: PsychTest
    let member: Member?
    var showName = true
    var includeNote = false

    static let width: CGFloat = 375

    var body: some View {
        let eval = test.evaluate(record)
        VStack(spacing: 0) {
            brandHeader

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    AvatarView(member: member).frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(showName ? (member?.name ?? "我") : "一位 Gnothi 用户")
                            .font(.app(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(Formatters.shortDate.string(from: record.date))
                            .font(.app(12))
                            .foregroundStyle(Theme.subInk)
                    }
                    Spacer()
                    Chip(text: test.title, tint: test.tint)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(eval.headline)
                        .font(.app(30, .bold))
                        .foregroundStyle(Theme.ink)
                    Chip(text: eval.scoreText, tint: eval.color)
                }

                if eval.dimensionScores.count > 1 {
                    RadarChart(labels: eval.dimensionScores.map { $0.dimension.name },
                               values: eval.dimensionScores.map { $0.value / 100 },
                               tint: test.tint)
                        .frame(height: 210)
                    VStack(spacing: 10) {
                        ForEach(eval.dimensionScores) { item in
                            HStack(spacing: 10) {
                                Text(item.dimension.name)
                                    .font(.app(13, .medium))
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 62, alignment: .leading)
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Theme.line)
                                        Capsule().fill(item.dimension.color)
                                            .frame(width: max(6, g.size.width * item.value / 100))
                                    }
                                }
                                .frame(height: 7)
                                Text("\(Int(item.value.rounded()))%")
                                    .font(.app(13, .bold))
                                    .foregroundStyle(Theme.ink)
                                    .monospacedDigit()
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                } else if !test.bands.isEmpty {
                    BandGauge(score: record.total, maxScore: test.chartMax, bands: test.bands)
                        .padding(.vertical, 4)
                }

                Text(eval.summary)
                    .font(.app(14))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if includeNote && !record.note.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle().fill(test.tint).frame(width: 3)
                        Text(record.note)
                            .font(.app(14))
                            .italic()
                            .foregroundStyle(Theme.ink.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(22)

            footer
        }
        .frame(width: Self.width)
        .background(Color.white)
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            AppMark()
                .frame(width: 46, height: 46)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(AppInfo.name) · \(AppInfo.chineseName)")
                    .font(.app(18, .bold))
                    .foregroundStyle(Theme.outline)
                Text(AppInfo.slogan)
                    .font(.app(12))
                    .foregroundStyle(Theme.outline.opacity(0.65))
            }
            Spacer()
            Sparkle().fill(Theme.lavender).frame(width: 14, height: 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(colors: [Theme.peach.opacity(0.35), Theme.butter.opacity(0.3), Theme.lavender.opacity(0.3)],
                           startPoint: .leading, endPoint: .trailing)
        )
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("和家人一起，记录心理成长的轨迹")
                    .font(.app(13, .semibold))
                    .foregroundStyle(Theme.outline)
                Text("扫码下载 · \(AppInfo.downloadHint)")
                    .font(.app(11))
                    .foregroundStyle(Theme.outline.opacity(0.7))
                Text("结果仅供自我了解，不构成医学诊断")
                    .font(.app(9))
                    .foregroundStyle(Theme.outline.opacity(0.45))
            }
            Spacer()
            if let qr = QRCode.image(for: AppInfo.appStoreURL.absoluteString) {
                Image(decorative: qr, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 62, height: 62)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(hex: 0xFBF7F1))
    }
}

// MARK: - Export sheet

struct ReportExportView: View {
    let record: TestRecord
    let test: PsychTest
    @Environment(\.dismiss) private var dismiss
    @Query private var members: [Member]
    @State private var showName = true
    @State private var includeNote = false
    @State private var image: CGImage?
    @State private var saving = false
    @State private var message: String?
    @State private var savedCount = 0

    private var member: Member? { members.first { $0.id == record.memberID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Group {
                        if let image {
                            Image(decorative: image, scale: 3)
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView().frame(height: 300)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
                    .padding(.horizontal, 8)

                    VStack(spacing: 14) {
                        Toggle(isOn: $showName) {
                            Text("显示成员名字").font(.app(15, .medium)).foregroundStyle(Theme.ink)
                        }
                        Divider().overlay(Theme.line)
                        Toggle(isOn: $includeNote) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("附上「此刻的我」").font(.app(15, .medium)).foregroundStyle(Theme.ink)
                                if record.note.isEmpty {
                                    Text("这次没有写随笔").font(.app(12)).foregroundStyle(Theme.subInk)
                                }
                            }
                        }
                        .disabled(record.note.isEmpty)
                    }
                    .toggleStyle(.switch)
                    .tint(Theme.leaf)
                    .card()

                    HStack(spacing: 12) {
                        Button {
                            Task { await save() }
                        } label: {
                            if saving {
                                ProgressView().tint(Theme.background)
                            } else {
                                Label(ImageSaver.actionTitle, systemImage: ImageSaver.actionIcon)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(image == nil || saving)

                        if let image {
                            ShareLink(item: Image(decorative: image, scale: 3),
                                      preview: SharePreview("\(test.title) · Gnothi", image: Image(decorative: image, scale: 3))) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 56, height: 56)
                                    .background(Circle().fill(Theme.card))
                                    .overlay(Circle().stroke(Theme.line, lineWidth: 1.5))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("报告图片")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }.foregroundStyle(Theme.subInk)
                }
            }
            .onAppear(perform: render)
            .onChange(of: showName) { _, _ in render() }
            .onChange(of: includeNote) { _, _ in render() }
            .sensoryFeedback(.success, trigger: savedCount)
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("好的", role: .cancel) {}
            }
        }
    }

    @MainActor
    private func render() {
        let card = ReportCardView(record: record, test: test, member: member,
                                  showName: showName, includeNote: includeNote)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        image = renderer.cgImage
    }

    @MainActor
    private func save() async {
        guard let image else { return }
        saving = true
        let name = "Gnothi-\(test.title)-\(Formatters.shortDate.string(from: record.date))"
        let result = await ImageSaver.save(image, suggestedName: name)
        saving = false
        switch result {
        case .saved(let text):
            savedCount += 1
            message = text
        case .failed(let text):
            message = text
        case .cancelled:
            break
        }
    }
}
