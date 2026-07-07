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

    /// 슬롯 store를 생성합니다.
    ///
    /// - Parameter adUnitID: 사용할 AdMob 네이티브 광고 단위 ID입니다. 기본값은 앱 설정의 현재 네이티브 광고 단위 ID입니다.
    public init(adUnitID: String = Constants.AdMob.currentNativeAdUnitId) {
        self.adUnitID = adUnitID
    }

    /// 슬롯 id에 해당하는 광고 ViewModel을 반환합니다.
    ///
    /// 아직 생성되지 않은 슬롯이면 새 ViewModel을 생성하고, 하위 ViewModel 변경을 상위 store 변경으로 전달합니다.
    ///
    /// - Parameter slotID: 광고 슬롯 식별자입니다.
    /// - Returns: 슬롯 전용 광고 ViewModel입니다.
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

    /// 슬롯 id 목록에 해당하는 광고를 아직 로드하지 않았다면 요청합니다.
    ///
    /// - Parameter slotIDs: 광고를 로드할 슬롯 id 목록입니다.
    public func loadAdIfNeeded(for slotIDs: [String]) {
        for slotID in stableUniqueIDs(slotIDs) {
            viewModel(for: slotID).loadAdIfNeeded()
        }
    }

    /// 특정 슬롯에 렌더링 가능한 광고가 로드되었는지 반환합니다.
    ///
    /// - Parameter slotID: 확인할 광고 슬롯 식별자입니다.
    /// - Returns: 광고 로드 여부입니다.
    public func hasLoadedAd(for slotID: String) -> Bool {
        viewModels[slotID]?.hasLoadedAd == true
    }

    /// 전달된 슬롯 중 렌더링 가능한 광고가 로드된 슬롯 id 집합을 반환합니다.
    ///
    /// - Parameter slotIDs: 확인할 광고 슬롯 식별자 목록입니다.
    /// - Returns: 광고가 로드된 슬롯 id 집합입니다.
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
