import SwiftUI

private enum SpriteLayout {
    static let size: CGFloat = 64
    static let usableWidthFraction: CGFloat = 0.8
    static let leftMarginFraction: CGFloat = 0.1

    static func xOffset(xPosition: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let usableWidth = totalWidth * usableWidthFraction
        let leftMargin = totalWidth * leftMarginFraction
        return leftMargin + (xPosition * usableWidth) - (totalWidth / 2)
    }

    static func depthSorted(_ sessions: [SessionData]) -> [SessionData] {
        sessions.sorted { $0.spriteYOffset < $1.spriteYOffset }
    }
}

// MARK: - Visual layer (placed in .background, no interaction)

struct GrassIslandView: View {
    let sessions: [SessionData]
    var selectedSessionId: String?
    var hoveredSessionId: String?

    private let patchWidth: CGFloat = 80

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    ForEach(0..<patchCount(for: geometry.size.width), id: \.self) { _ in
                        Image("GrassIsland")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: patchWidth, height: geometry.size.height)
                            .clipped()
                    }
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .drawingGroup()

                if !sessions.isEmpty {
                    ForEach(SpriteLayout.depthSorted(sessions)) { session in
                        GrassSpriteView(
                            state: session.state,
                            xPosition: session.spriteXPosition,
                            yOffset: session.spriteYOffset,
                            totalWidth: geometry.size.width,
                            glowOpacity: glowOpacity(for: session.id),
                            dragOffset: session.dragOffset,
                            isDragging: session.isDragging
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
        }
        .clipped()
        .allowsHitTesting(false)
    }

    private func glowOpacity(for sessionId: String) -> Double {
        if sessionId == selectedSessionId { return 0.7 }
        if sessionId == hoveredSessionId { return 0.3 }
        return 0
    }

    private func patchCount(for width: CGFloat) -> Int {
        Int(ceil(width / patchWidth)) + 1
    }
}

// MARK: - Interaction layer (placed in .overlay for reliable hit testing)

struct GrassTapOverlay: View {
    let sessions: [SessionData]
    var selectedSessionId: String?
    @Binding var hoveredSessionId: String?
    var onSelectSession: ((String) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.clear

                if !sessions.isEmpty {
                    ForEach(SpriteLayout.depthSorted(sessions)) { session in
                        SpriteTapTarget(
                            session: session,
                            xPosition: session.spriteXPosition,
                            yOffset: session.spriteYOffset,
                            totalWidth: geometry.size.width,
                            grassSize: geometry.size,
                            hoveredSessionId: $hoveredSessionId,
                            onTap: { onSelectSession?(session.id) }
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            .coordinateSpace(name: "grassArea")
        }
    }
}

// MARK: - Private views

private struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct SpriteTapTarget: View {
    let session: SessionData
    let xPosition: CGFloat
    let yOffset: CGFloat
    let totalWidth: CGFloat
    let grassSize: CGSize
    @Binding var hoveredSessionId: String?
    var onTap: (() -> Void)?

    @State private var tapScale: CGFloat = 1.0
    @State private var isDragging = false
    @State private var dragStart: CGSize = .zero

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: SpriteLayout.size, height: SpriteLayout.size)
            .contentShape(Rectangle())
            .scaleEffect(tapScale)
            .onHover { hovering in
                hoveredSessionId = hovering ? session.id : nil
            }
            .offset(
                x: SpriteLayout.xOffset(xPosition: xPosition, totalWidth: totalWidth) + session.dragOffset.width,
                y: yOffset + session.dragOffset.height
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named("grassArea"))
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStart = session.dragOffset
                            session.isDragging = true
                        }
                        let proposed = CGSize(
                            width: dragStart.width + value.translation.width,
                            height: dragStart.height + value.translation.height
                        )
                        session.dragOffset = clampedOffset(proposed)
                    }
                    .onEnded { _ in
                        isDragging = false
                        session.isDragging = false
                    }
            )
            .onTapGesture {
                handleTap()
            }
    }

    private func clampedOffset(_ proposed: CGSize) -> CGSize {
        let baseX = SpriteLayout.xOffset(xPosition: xPosition, totalWidth: totalWidth)
        let spriteHalf = SpriteLayout.size / 2

        let minX = -(totalWidth / 2) + spriteHalf - baseX
        let maxX = (totalWidth / 2) - spriteHalf - baseX

        let minY = -(grassSize.height) - yOffset + spriteHalf
        let maxY = -yOffset - spriteHalf

        return CGSize(
            width: min(max(proposed.width, minX), maxX),
            height: min(max(proposed.height, minY), maxY)
        )
    }

    private func handleTap() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { tapScale = 1.15 }
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { tapScale = 1.0 }
        }
        onTap?()
    }
}

private struct GrassSpriteView: View {
    let state: NotchiState
    let xPosition: CGFloat
    let yOffset: CGFloat
    let totalWidth: CGFloat
    var glowOpacity: Double = 0
    var dragOffset: CGSize = .zero
    var isDragging: Bool = false
    @State private var character = AppSettings.selectedCharacter

    private static let draggingSpriteSheet = "notchi_dragging"
    private static let draggingFrameCount = 6
    private static let draggingColumns = 6
    private static let draggingFPS: Double = 8.0

    private let swayDuration: Double = 2.0
    private var bobAmplitude: CGFloat {
        guard state.bobAmplitude > 0 else { return 0 }
        return state.task == .working ? 1.5 : 1
    }
    private let glowColor = Color(red: 0.4, green: 0.7, blue: 1.0)

    private var swayAmplitude: Double {
        (state.task == .sleeping || state.task == .compacting) ? 0 : state.swayAmplitude
    }

    private var isAnimatingMotion: Bool {
        bobAmplitude > 0 || swayAmplitude > 0 || state.emotion == .sob
    }

    private var bobDuration: Double {
        state.task == .working ? 1.0 : state.bobDuration
    }

    private func swayDegrees(at date: Date) -> Double {
        guard swayAmplitude > 0 else { return 0 }
        let t = date.timeIntervalSinceReferenceDate
        let phase = (t / swayDuration).truncatingRemainder(dividingBy: 1.0)
        return sin(phase * .pi * 2) * swayAmplitude
    }

    private static let sobTrembleAmplitude: CGFloat = 0.3

    private var activeSpriteSheet: String {
        if isDragging {
            let prefix = character.spritePrefix
            let draggingName = "\(prefix)_dragging"
            if NSImage(named: draggingName) != nil {
                return draggingName
            }
            // For Bocchi, use "waiting_sad" for dragging if no specific dragging sprite exists,
            // as it has her iconic terrified/blue-face expression and native head-shaking frames.
            if character == .bocchi {
                return "bocchi_waiting_sad"
            }
            return "\(prefix)_idle_sob"
        }
        return state.spriteSheetName(for: character)
    }

    private var activeFrameCount: Int {
        if isDragging {
            let prefix = character.spritePrefix
            if NSImage(named: "\(prefix)_dragging") != nil {
                return Self.draggingFrameCount
            }
            // Use 6 frames for the muri-muri animation (3x2 grid).
            return 6
        }
        return state.frameCount
    }

    private var activeColumns: Int {
        if isDragging {
            let prefix = character.spritePrefix
            if NSImage(named: "\(prefix)_dragging") != nil {
                return Self.draggingColumns
            }
            // Bocchi's muri-muri uses a 3x2 grid (3 columns).
            if character == .bocchi {
                return 3
            }
            return 6
        }
        return state.columns
    }

    private var activeFPS: Double {
        isDragging ? Self.draggingFPS : state.animationFPS
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isAnimatingMotion && !isDragging)) { timeline in
            SpriteSheetView(
                spriteSheet: activeSpriteSheet,
                frameCount: activeFrameCount,
                columns: activeColumns,
                fps: activeFPS,
                isAnimating: true
            )
            .frame(width: SpriteLayout.size, height: SpriteLayout.size)
            .background(alignment: .bottom) {
                if glowOpacity > 0 && !isDragging {
                    Ellipse()
                        .fill(glowColor.opacity(glowOpacity))
                        .frame(width: SpriteLayout.size * 0.85, height: SpriteLayout.size * 0.25)
                        .blur(radius: 8)
                        .offset(y: 4)
                }
            }
            .rotationEffect(.degrees(isDragging ? 0 : swayDegrees(at: timeline.date)), anchor: .bottom)
            .offset(
                x: SpriteLayout.xOffset(xPosition: xPosition, totalWidth: totalWidth) + dragOffset.width + trembleOffset(at: timeline.date, amplitude: state.emotion == .sob ? Self.sobTrembleAmplitude : 0),
                y: yOffset + dragOffset.height + bobOffset(at: timeline.date, duration: bobDuration, amplitude: isDragging ? 0 : bobAmplitude)
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .characterThemeDidChange)) { _ in
            character = AppSettings.selectedCharacter
        }
    }
}
