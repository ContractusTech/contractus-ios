import SwiftUI

// swiftlint:disable all
public struct BottomSheetView<Header: View, Content: View, Footer: View, PositionEnum: RawRepresentable>: View where PositionEnum.RawValue == CGFloat, PositionEnum: CaseIterable, PositionEnum: Equatable {
    @State private var bottomSheetTranslation: CGFloat
    @State private var initialVelocity: Double = 0.0

    @Binding var position: PositionEnum

    let header: Header
    let content: Content
    let pinnedFooter: Footer
    let frameHeight: CGFloat
    var bottomSheetTranslationHeight: CGFloat {
        return UIScreen.main.bounds.height < bottomSheetTranslation ?
        UIScreen.main.bounds.height : bottomSheetTranslation
    }
    var deltaOffset: CGFloat {
        return UIScreen.main.bounds.height < bottomSheetTranslation ?
        bottomSheetTranslation - UIScreen.main.bounds.height : 0
    }
    
    private var AnimationModel: Contractus.AnimationModel = Contractus.AnimationModel(
        mass: BottomSheetDefaults.Animation.mass,
        stiffness: BottomSheetDefaults.Animation.stiffness,
        damping: BottomSheetDefaults.Animation.damping
    )
    
    private var threshold = BottomSheetDefaults.Interaction.threshold
    private var excludedPositions: [PositionEnum] = []
    private var isDraggable = true
    private var showBackground = false

    private var onBottomSheetDrag: ((_ position: CGFloat) -> Void)?

    public init(
        position: Binding<PositionEnum>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder pinnedFooter: () -> Footer
    ) {
        let lastPosition = PositionEnum.allCases.sorted(by: { $0.rawValue < $1.rawValue }).last!.rawValue
        
        if lastPosition <= 1 {
            PositionModel.type = .relative
            
            self._bottomSheetTranslation = State(initialValue: position.wrappedValue.rawValue * UIScreen.main.bounds.height)
            self.frameHeight = lastPosition * UIScreen.main.bounds.height
        } else {
            PositionModel.type = .absolute
            
            self._bottomSheetTranslation = State(initialValue: position.wrappedValue.rawValue)
            self.frameHeight = lastPosition
        }
        
        self._position = position

        self.header = header()
        self.content = content()
        self.pinnedFooter = pinnedFooter()
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(showBackground ? 0.2 : 0))
                    .edgesIgnoringSafeArea(.all)
                    .animation(.default)
                // MARK: - Main bottom panel
                UIKitBottomSheetViewController(
                    bottomSheetTranslation: $bottomSheetTranslation,
                    initialVelocity: $initialVelocity,
                    bottomSheetPosition: $position,
                    isDraggable: isDraggable,
                    threshold: threshold,
                    excludedPositions: excludedPositions,
                    header: {
                        VStack {
                            header
                                .zIndex(1)
                        }
                    },
                    content: {
                        GeometryReader { _ in
                            content
                        }
                    }
                )
                .onChange(of: $position.wrappedValue) { newValue in
                    position = newValue
                    
                    if PositionModel.type == .relative {
                        bottomSheetTranslation = newValue.rawValue * UIScreen.main.bounds.height
                    } else {
                        bottomSheetTranslation = newValue.rawValue
                    }
                }
                .onAnimationChange(of: bottomSheetTranslation) { newValue in
                    onBottomSheetDrag?(newValue)
                }
                .frame(height: frameHeight)
                .offset(y: (geometry.size.height + geometry.safeAreaInsets.bottom) - bottomSheetTranslationHeight)
                .animation(
                    .interpolatingSpring(
                        mass: AnimationModel.mass,
                        stiffness: AnimationModel.stiffness,
                        damping: AnimationModel.damping,
                        initialVelocity: initialVelocity * 10
                    ),
                    value: geometry.size.height - (bottomSheetTranslationHeight * geometry.size.height)
                )
                // MARK: - Pined footer at bottom over main panel
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.01), Color.white]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 16)
                    pinnedFooter
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 14)
                        .contentShape(Rectangle())
                        .background(Color.white)
                }
                .offset(y: bottomSheetTranslationHeight < 100
                        ? geometry.size.height - bottomSheetTranslationHeight
                        : geometry.safeAreaInsets.bottom - deltaOffset > 0 ? 0 : -14 - deltaOffset)
                .animation(.default)
            }
        }
    }
}

// MARK: - Properties
extension BottomSheetView {
    public func animationCurve(mass: Double = 1.2, stiffness: Double = 200, damping: Double = 25) -> BottomSheetView {
        var bottomSheetView = self
        bottomSheetView.AnimationModel = Contractus.AnimationModel(
            mass: mass,
            stiffness: stiffness,
            damping: damping
        )
        return bottomSheetView
    }
    
    public func snapThreshold(_ threshold: Double = 0) -> BottomSheetView {
        var bottomSheetView = self
        bottomSheetView.threshold = threshold
        return bottomSheetView
    }
    
    public func isDraggable(_ isDraggable: Bool) -> BottomSheetView {
        var bottomSheetView = self
        bottomSheetView.isDraggable = isDraggable
        return bottomSheetView
    }
    
    public func excludeSnapPositions(_ positions: [PositionEnum]) -> BottomSheetView {
        var bottomSheetView = self
        bottomSheetView.excludedPositions = positions
        return bottomSheetView
    }
    
    public func showBackground(_ show: Bool) -> BottomSheetView {
        var bottomSheetView = self
        bottomSheetView.showBackground = show
        return bottomSheetView
    }
}

// MARK: - Closures
extension BottomSheetView {
    public func onBottomSheetDrag(perform: @escaping (CGFloat) -> Void) -> BottomSheetView {
        var bottomSheetView = self
        bottomSheetView.onBottomSheetDrag = perform
        return bottomSheetView
    }
}

// MARK: - Convenience initializers
extension BottomSheetView where Header == EmptyView, Footer == EmptyView {
    init(
        position: Binding<PositionEnum>,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            position: position,
            header: { EmptyView() },
            content: content,
            pinnedFooter: { EmptyView() }
        )
    }
}

extension BottomSheetView where Header == EmptyView {
    init(
        position: Binding<PositionEnum>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder pinnedFooter: () -> Footer
    ) {
        self.init(
            position: position,
            header: { EmptyView() },
            content: content,
            pinnedFooter: pinnedFooter
        )
    }
}

extension BottomSheetView where Footer == EmptyView {
    init(
        position: Binding<PositionEnum>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            position: position,
            header: header,
            content: content,
            pinnedFooter: { EmptyView() }
        )
    }
}
