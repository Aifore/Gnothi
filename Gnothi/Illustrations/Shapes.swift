import SwiftUI

// MARK: - Deterministic random (同一个 seed 永远画出同一个形状)

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 0x9E37_79B9_7F4A_7C15 &+ 1
    }

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}

extension Path {
    /// 用 Catmull-Rom 曲线把点连成平滑闭合曲线
    static func smoothClosed(_ pts: [CGPoint]) -> Path {
        var path = Path()
        let n = pts.count
        guard n > 2 else { return path }
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Organic shapes

/// 有机的"水滴/鹅卵石"形状，插画风的核心元素
struct Blob: Shape {
    var seed: Int = 1
    var points: Int = 7
    var variance: CGFloat = 0.16

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: UInt64(max(seed, 0)))
        let rx = rect.width / 2
        let ry = rect.height / 2
        var pts: [CGPoint] = []
        for i in 0..<points {
            let angle = CGFloat(i) / CGFloat(points) * 2 * .pi
            let r = 1 - variance * rng.next()
            pts.append(CGPoint(x: rect.midX + cos(angle) * rx * r,
                               y: rect.midY + sin(angle) * ry * r))
        }
        return Path.smoothClosed(pts)
    }
}

struct Leaf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.minX - rect.width * 0.25, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX + rect.width * 0.25, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: rect.maxY), control: c)
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: rect.minY), control: c)
        p.closeSubpath()
        return p
    }
}

/// 底部的一道山丘
struct Hill: Shape {
    var peak: CGFloat = 0.3

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45),
                   control1: CGPoint(x: rect.minX + rect.width * peak, y: rect.minY - rect.height * 0.15),
                   control2: CGPoint(x: rect.minX + rect.width * min(peak + 0.35, 1), y: rect.minY + rect.height * 0.85))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct Mountain: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.15))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX - rect.width * 0.32, y: rect.minY + rect.height * 0.15))
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// 花盆（上宽下窄）
struct Pot: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = rect.width * 0.14
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + inset, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.maxY + 4))
        p.closeSubpath()
        return p
    }
}

/// 正弦波浪线（描边用）
struct Wave: Shape {
    var amplitude: CGFloat = 0.3
    var cycles: CGFloat = 2

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 60
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = rect.minX + t * rect.width
            let y = rect.midY + sin(t * cycles * 2 * .pi) * rect.height * amplitude
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}

/// 蜿蜒小路（描边用）
struct WindingPath: Shape {
    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var p = Path()
        p.move(to: pt(0.05, 1))
        p.addCurve(to: pt(0.5, 0.55), control1: pt(0.85, 0.95), control2: pt(0.05, 0.72))
        p.addCurve(to: pt(0.92, 0.0), control1: pt(0.95, 0.4), control2: pt(0.6, 0.18))
        return p
    }
}

/// 弧线：curve > 0 为微笑 ‿，curve < 0 为拱形 ⌒
struct Arc: Shape {
    var curve: CGFloat

    var animatableData: CGFloat {
        get { curve }
        set { curve = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                       control: CGPoint(x: rect.midX, y: rect.midY + curve * rect.height))
        return p
    }
}
