import Core
import SwiftUI

public struct MapFeatureView: View {
    @Environment(MapFeatureCoordinator.self) private var coordinator
    @State private var query = ""
    @State private var selectedCategory = "전체"

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.teal.opacity(0.18), Color.white, Color.orange.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    TextField("궁금한 팝업을 검색", text: $query)
                        .textFieldStyle(.roundedBorder)

                    Button("지역") {
                        coordinator.presentBottomSheet(.popupList)
                    }
                    .buttonStyle(.bordered)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? Color.black : Color.white)
                            .clipShape(Capsule())
                        }
                    }
                }

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.teal)
                            Text("NMapsMap 브리지 이식 대상")
                                .font(.headline)
                            Text("마커 선택 시 상세, 목록 보기, 현재 위치 이동, 1차/2차 시트를 모두 선언형으로 복원해야 합니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }

                List(filteredResults, id: \.title) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.region)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("상세") {
                            coordinator.presentBottomSheet(.popupDetail)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .listStyle(.plain)
            }
            .padding(16)

            HStack(spacing: 12) {
                Button("목록 시트") {
                    coordinator.presentBottomSheet(.popupList)
                }
                .buttonStyle(.borderedProminent)

                Button("상세 시트") {
                    coordinator.presentBottomSheet(.popupDetail)
                }
                .buttonStyle(.bordered)

                Button("닫기") {
                    coordinator.dismissBottomSheet()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 16)
        }
    }
}

private extension MapFeatureView {
    var categories: [String] {
        ["전체", "패션", "전시", "푸드", "캐릭터", "체험"]
    }

    var filteredResults: [(title: String, region: String)] {
        let source = [
            ("성수 편집숍 팝업", "성수"),
            ("잠실 스포츠 콜라보", "잠실"),
            ("홍대 전시형 팝업", "홍대"),
        ]

        return source.filter {
            (query.isEmpty || $0.0.localizedCaseInsensitiveContains(query)) &&
            (selectedCategory == "전체" || $0.0.localizedCaseInsensitiveContains(selectedCategory))
        }
    }
}
