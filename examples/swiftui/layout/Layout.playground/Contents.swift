//: A SwiftUI based Playground for presenting user interface

import SwiftUI
import PlaygroundSupport

// Present the view controller in the Live View window
PlaygroundPage.current.setLiveView(ContentView())

struct ContentView: View {
    var subviews: some View {
        ForEach(0...9, id: \.self) { number in
            Text("Tag \(Int(pow(10, Double(number))))")
                .foregroundColor(Color.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue)
                .clipShape(Capsule())
        }
    }

    var body: some View {
        TagView(interitemSpacing: 8, lineSpacing: 6) {
            subviews
        }
        .padding(20)
        .overlay(Rectangle().stroke(.black))
        .frame(width: 400, height: 300)
    }
}

struct TagView: Layout {
    let interitemSpacing: Double
    let lineSpacing: Double

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        computePositions(subviews: subviews, maxWidth: proposal.width ?? 0)
            .reduce(CGSize.zero, { size, value in CGSize(width: max(size.width, value.maxX), height: max(size.height, value.maxY)) })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let positions = computePositions(subviews: subviews, maxWidth: bounds.width)

        for index in 0..<positions.count {
            guard subviews.indices.contains(index) else { continue }
            let finalPosition = positions[index].offset(by: bounds.origin)
            subviews[index].place(at: finalPosition.origin, anchor: .topLeading, proposal: .unspecified)
        }
    }

    /// Compute top-left position of every subview in given layout space.
    func computePositions(subviews: Subviews, maxWidth: CGFloat) -> [CGRect] {
        var maxHeight: Double = 0
        var currentPosition: CGPoint = .zero    // top-right position of currently processed subview
        var result: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)   // subview ideal size
            if currentPosition.x > 0 {
                currentPosition.x += interitemSpacing
            }

            if currentPosition.x > 0, currentPosition.x + size.width > maxWidth {
                currentPosition.y = maxHeight + lineSpacing
                currentPosition.x = 0
            } else {
                maxHeight = max(maxHeight, currentPosition.y + size.height)
            }

            result.append(.init(origin: currentPosition, size: size))
            currentPosition.x += size.width
        }

        return result
    }
}

extension CGRect {
    func offset(by point: CGPoint) -> CGRect {
        .init(origin: .init(x: origin.x + point.x, y: origin.y + point.y), size: size)
    }
}

