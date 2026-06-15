import Combine
import Core
import Foundation

/// 여러 네이티브 광고 슬롯의 ViewModel을 관리하는 store입니다.
///
/// 같은 광고 객체를 여러 셀에 재사용하지 않도록 슬롯 id마다 별도 `AdNativeAdViewModel`을 생성합니다.
@MainActor
public final class AdNativeAdSlotStore: ObservableObject {
    private let adUnitID: String
    private var viewModels: [String: AdNativeAdViewModel] = [:]
    private var cancellables: [String: AnyCancellable] = [:]

    public init(adUnitID: String = Constants.AdMob.currentNativeAdUnitId) {
        self.adUnitID = adUnitID
    }

    public func viewModel(for slotID: String) -> AdNativeAdViewModel {
        if let viewModel = viewModels[slotID] {
            return viewModel
        }

        let viewModel = AdNativeAdViewModel(adUnitID: adUnitID)
        viewModels[slotID] = viewModel
        cancellables[slotID] = viewModel.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
        return viewModel
    }

    public func loadAdIfNeeded(for slotIDs: [String]) {
        for slotID in stableUniqueIDs(slotIDs) {
            viewModel(for: slotID).loadAdIfNeeded()
        }
    }

    public func hasLoadedAd(for slotID: String) -> Bool {
        viewModels[slotID]?.hasLoadedAd == true
    }

    public func loadedSlotIDs(in slotIDs: [String]) -> Set<String> {
        Set(stableUniqueIDs(slotIDs).filter { hasLoadedAd(for: $0) })
    }
}

private extension AdNativeAdSlotStore {
    func stableUniqueIDs(_ slotIDs: [String]) -> [String] {
        var uniqueIDs: [String] = []
        var seenIDs: Set<String> = []

        for slotID in slotIDs where seenIDs.contains(slotID) == false {
            uniqueIDs.append(slotID)
            seenIDs.insert(slotID)
        }

        return uniqueIDs
    }
}
