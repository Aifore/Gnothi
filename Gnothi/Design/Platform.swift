import SwiftUI

/// iOS / macOS 差异集中在这里，业务代码保持一份
enum Platform {
    #if os(macOS)
    static let isMac = true
    static let biometricName = "Touch ID"
    #else
    static let isMac = false
    static let biometricName = "Face ID"
    #endif
}

extension View {
    /// 导航栏标题内联显示（macOS 无此概念）
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// 隐藏导航栏（页面自己画标题）
    @ViewBuilder
    func hiddenNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    /// 宽屏（Mac 窗口）时限制内容宽度并居中
    func readableWidth(_ maxWidth: CGFloat = 760) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }

    /// Mac 上 sheet 默认很小，给一个合适的尺寸
    @ViewBuilder
    func macSheetSize(width: CGFloat = 520, height: CGFloat = 680) -> some View {
        #if os(macOS)
        self.frame(minWidth: width, idealWidth: width, minHeight: height, idealHeight: height)
        #else
        self
        #endif
    }

    /// 测试流程：iPhone 全屏覆盖，Mac 用大尺寸 sheet
    @ViewBuilder
    func testCover<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                      @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        #if os(iOS)
        self.fullScreenCover(item: item, content: content)
        #else
        self.sheet(item: item) { value in
            content(value).frame(minWidth: 620, idealWidth: 660, minHeight: 740, idealHeight: 800)
        }
        #endif
    }
}
