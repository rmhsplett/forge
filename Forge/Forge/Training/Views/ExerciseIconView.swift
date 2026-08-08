import SwiftUI

/// Icon for an exercise, chosen by equipment type. Most types use an SF
/// Symbol; kettlebell and cable have no suitable system glyph, so they're
/// drawn as custom SwiftUI shapes. Fills its frame — size it at the call site
/// with `.frame(width:height:)`.
struct ExerciseIconView: View {

    let displayType: ExerciseDisplayType
    var color: Color = .secondary

    var body: some View {
        switch displayType {
        case .kettlebell:
            KettlebellGlyph(color: color)
        case .cable:
            CableTowerGlyph(color: color)
        default:
            Image(systemName: displayType.symbolName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(color)
                .padding(1)
        }
    }
}

/// A kettlebell: filled bell body with a stroked handle arch on top.
private struct KettlebellGlyph: View {
    var color: Color = .secondary

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let ox = (size.width - s) / 2
            let oy = (size.height - s) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: ox + x / 100 * s, y: oy + y / 100 * s)
            }
            let shading = GraphicsContext.Shading.color(color)

            // Bell body.
            let body = Path(ellipseIn: CGRect(
                x: ox + 21 / 100 * s, y: oy + 37 / 100 * s,
                width: 58 / 100 * s, height: 58 / 100 * s
            ))
            ctx.fill(body, with: shading)

            // Handle arch.
            var handle = Path()
            handle.move(to: p(36, 54))
            handle.addCurve(to: p(50, 20), control1: p(34, 30), control2: p(41, 20))
            handle.addCurve(to: p(64, 54), control1: p(59, 20), control2: p(66, 30))
            ctx.stroke(handle, with: shading,
                       style: StrokeStyle(lineWidth: 10 / 100 * s, lineCap: .round, lineJoin: .round))
        }
    }
}

/// A cable tower: top mount + pulley + cable + pulldown handle + weight stack.
private struct CableTowerGlyph: View {
    var color: Color = .secondary

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let ox = (size.width - s) / 2
            let oy = (size.height - s) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: ox + x / 100 * s, y: oy + y / 100 * s)
            }
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: ox + x / 100 * s, y: oy + y / 100 * s, width: w / 100 * s, height: h / 100 * s)
            }
            let shading = GraphicsContext.Shading.color(color)
            let line = StrokeStyle(lineWidth: 5.5 / 100 * s, lineCap: .round, lineJoin: .round)
            let radius = 3.0 / 100 * s

            // Top mounting bar.
            ctx.fill(Path(roundedRect: r(24, 14, 52, 7), cornerRadius: radius), with: shading)
            // Pulley.
            ctx.stroke(Path(ellipseIn: r(44, 23, 12, 12)), with: shading, style: line)
            // Cable.
            var cable = Path()
            cable.move(to: p(50, 35)); cable.addLine(to: p(50, 50))
            ctx.stroke(cable, with: shading, style: line)
            // Pulldown handle bar.
            ctx.fill(Path(roundedRect: r(33, 50, 34, 8), cornerRadius: 4 / 100 * s), with: shading)
            // Weight stack.
            ctx.stroke(Path(roundedRect: r(40, 70, 20, 22), cornerRadius: radius), with: shading, style: line)
            var d1 = Path(); d1.move(to: p(40, 78)); d1.addLine(to: p(60, 78))
            ctx.stroke(d1, with: shading, style: line)
            var d2 = Path(); d2.move(to: p(40, 85)); d2.addLine(to: p(60, 85))
            ctx.stroke(d2, with: shading, style: line)
        }
    }
}
