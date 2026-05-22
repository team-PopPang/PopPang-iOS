import Core
import MapFeature
import Testing
@testable import Coordinator

struct CoordinatorTests {
    @Test
    @MainActor
    func rootCoordinatorChangesDestination() {
        let store = RootCoordinator()

        #expect(store.destination == .launch)

        store.showOnboarding()
        #expect(store.destination == .onboarding)

        store.showAuthFlow()
        #expect(store.destination == .auth)

        store.showMainFlow()
        #expect(store.destination == .main)
    }

    @Test
    @MainActor
    func coordinatorSupportsPushAndPop() {
        let store = Coordinator<
            Int,
            EmptySheetRoute,
            EmptyOverlayRoute,
            EmptyFullScreenRoute,
            EmptyBottomSheetRoute
        >()

        store.push(1)
        store.push(1)
        store.push(2)
        #expect(store.paths == [1, 2])

        store.pop()
        #expect(store.paths == [1])

        store.popToRoot()
        #expect(store.paths.isEmpty)
    }

    @Test
    @MainActor
    func coordinatorResetsBottomSheetDetentOnDismiss() {
        let coordinator = Coordinator<
            EmptyRoute,
            EmptySheetRoute,
            EmptyOverlayRoute,
            EmptyFullScreenRoute,
            MapBottomSheetRoute
        >()

        coordinator.presentBottomSheet(.popupList)
        #expect(coordinator.bottomSheet == .popupList)
        #expect(coordinator.bottomSheetPosition == .fraction(0.4))

        coordinator.updateBottomSheetPosition(.fraction(0.7))
        #expect(coordinator.bottomSheetPosition == .fraction(0.7))

        coordinator.dismissBottomSheet()
        #expect(coordinator.bottomSheet == nil)
        #expect(coordinator.bottomSheetPosition == .hidden)
    }

    @Test
    @MainActor
    func mapCoordinatorOwnsFeatureLocalBottomSheetState() {
        let coordinator = MapCoordinator()

        coordinator.showPopupDetailSheet()
        #expect(coordinator.bottomSheet == .popupDetail)

        coordinator.dismissBottomSheet()
        #expect(coordinator.bottomSheet == nil)
        #expect(coordinator.bottomSheetPosition == .hidden)
    }
}
