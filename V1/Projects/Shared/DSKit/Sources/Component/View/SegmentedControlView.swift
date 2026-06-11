import SwiftUI

public struct SegmentedControlView: View {
    @State private var selectedIndex = 0
    private let anyViews: [AnyView]

    let segments: [String]
    var background: Color
    var foreground: Color
    var height: CGFloat
    var font: UIFont

    public init(
        segments: [String],
        views: [any View],
        background: Color = .gray.opacity(0.3),
        foreground: Color = .blue,
        height: CGFloat = 4,
        font: UIFont = .scdream(.medium, size: 12)
    ) {
        self.segments = segments
        self.anyViews = views.map { AnyView($0) }
        self.background = background
        self.foreground = foreground
        self.height = height
        self.font = font
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(font)
                            .foregroundStyle(selectedIndex == index ? foreground : background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }

            GeometryReader { geometry in
                let segmentWidth = geometry.size.width / CGFloat(max(segments.count, 1))
                ZStack(alignment: .leading) {
                    Color.mainGray5.frame(height: 2)
                    Capsule()
                        .fill(foreground)
                        .frame(width: segmentWidth, height: height)
                        .offset(x: CGFloat(selectedIndex) * segmentWidth)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }
            .frame(height: height)

            SegmentedPageView(
                selectedIndex: $selectedIndex,
                views: anyViews
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct SegmentedPageView: UIViewControllerRepresentable {
    @Binding var selectedIndex: Int
    let views: [AnyView]

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        context.coordinator.updateViews(views)

        if let initialController = context.coordinator.controller(at: selectedIndex) {
            pageViewController.setViewControllers([initialController], direction: .forward, animated: false)
        }

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateViews(views)

        guard !views.isEmpty else {
            pageViewController.setViewControllers([], direction: .forward, animated: false)
            return
        }

        let boundedIndex = min(max(selectedIndex, 0), views.count - 1)
        if selectedIndex != boundedIndex {
            DispatchQueue.main.async {
                selectedIndex = boundedIndex
            }
        }

        context.coordinator.setSelectedIndex(
            boundedIndex,
            in: pageViewController,
            animated: context.transaction.animation != nil
        )
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: SegmentedPageView

        private var controllers: [UIHostingController<AnyView>] = []
        private var currentIndex = 0

        init(parent: SegmentedPageView) {
            self.parent = parent
        }

        func updateViews(_ views: [AnyView]) {
            if controllers.count != views.count {
                controllers = views.map {
                    let controller = UIHostingController(rootView: $0)
                    controller.view.backgroundColor = .clear
                    return controller
                }
            } else {
                for index in views.indices {
                    controllers[index].rootView = views[index]
                }
            }
        }

        func controller(at index: Int) -> UIHostingController<AnyView>? {
            guard controllers.indices.contains(index) else { return nil }
            return controllers[index]
        }

        func setSelectedIndex(
            _ index: Int,
            in pageViewController: UIPageViewController,
            animated: Bool
        ) {
            guard let controller = controller(at: index) else { return }
            guard pageViewController.viewControllers?.first !== controller else {
                currentIndex = index
                return
            }

            let direction: UIPageViewController.NavigationDirection = index >= currentIndex ? .forward : .reverse
            currentIndex = index
            pageViewController.setViewControllers([controller], direction: direction, animated: animated)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(where: { $0 === viewController }) else { return nil }
            return controller(at: index - 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(where: { $0 === viewController }) else { return nil }
            return controller(at: index + 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let visibleController = pageViewController.viewControllers?.first,
                  let index = controllers.firstIndex(where: { $0 === visibleController })
            else { return }

            currentIndex = index
            parent.selectedIndex = index
        }
    }
}
