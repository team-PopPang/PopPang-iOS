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
    func stackNavigationStoreSupportsPushAndPop() {
        let store = StackNavigationStore<Int>()

        store.push(1)
        store.push(1)
        store.push(2)
        #expect(store.path == [1, 2])

        store.pop()
        #expect(store.path == [1])

        store.popToRoot()
        #expect(store.path.isEmpty)
    }
}
