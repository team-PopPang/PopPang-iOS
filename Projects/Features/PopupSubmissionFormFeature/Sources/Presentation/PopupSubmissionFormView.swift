import ComposableArchitecture
import DSKit
import Domain
import SwiftUI

public struct PopupSubmissionFormView: View {
    @Bindable var store: StoreOf<PopupSubmissionFormFeature>

    public init(store: StoreOf<PopupSubmissionFormFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            requiredSection
            imageSection
            optionalSection
            if store.mode == .adminReview {
                adminSection
            }
        }
    }
}

private extension PopupSubmissionFormView {
    var requiredSection: some View {
        PopupSubmissionFormSection(title: "필수 입력") {
            PopupSubmissionTextInput(
                title: "팝업명",
                placeholder: "팝업명을 입력해 주세요",
                text: $store.name,
                isRequired: true
            )

            PopupSubmissionDateInput(
                title: "운영 기간",
                startDate: $store.startDate,
                endDate: $store.endDate
            )

            PopupSubmissionTextInput(
                title: "도로명 주소",
                placeholder: "예: 서울 성동구 성수이로 00",
                text: $store.roadAddress,
                isRequired: true
            )

            PopupSubmissionTextInput(
                title: "지역",
                placeholder: "예: 서울",
                text: $store.region,
                isRequired: true
            )

            if store.mode == .userCreate {
                PopupSubmissionTextEditor(
                    title: "제보 내용",
                    placeholder: "팝업의 주요 내용과 참고할 정보를 입력해 주세요",
                    text: $store.descriptionText,
                    isRequired: true
                )
            } else {
                PopupSubmissionTextEditor(
                    title: "팝업 한줄 소개",
                    placeholder: "노출용 한줄 소개를 입력해 주세요",
                    text: $store.captionSummary,
                    isRequired: true
                )

                PopupSubmissionTextEditor(
                    title: "팝업 상세 소개",
                    placeholder: "최종 노출용 상세 소개를 입력해 주세요",
                    text: $store.caption,
                    isRequired: true
                )
            }

            PopupSubmissionCategoryPicker(
                title: "추천 카테고리",
                categories: store.recommendList,
                selectedIds: store.selectedRecommendIds,
                isRequired: true
            ) { id in
                store.send(.recommendToggled(id))
            }
        }
    }

    var imageSection: some View {
        PopupSubmissionFormSection(title: "이미지 URL", isRequired: true) {
            VStack(spacing: 10) {
                ForEach(store.imageItems) { item in
                    HStack(spacing: 10) {
                        PopupSubmissionTextInput(
                            title: "",
                            placeholder: "https://...",
                            text: Binding(
                                get: { item.imageUrl },
                                set: { store.send(.imageURLChanged(item.id, $0)) }
                            ),
                            keyboardType: .URL,
                            textInputAutocapitalization: .never
                        )

                        Button {
                            store.send(.removeImageRow(item.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.mainRed)
                                .frame(width: 34, height: 48)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }

                Button {
                    store.send(.addImageRowTapped)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("이미지 URL 추가")
                            .font(.scdream(.medium, size: 12))
                        Spacer()
                    }
                    .foregroundStyle(Color.mainOrange)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.subWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.mainOrange, lineWidth: 1)
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    var optionalSection: some View {
        PopupSubmissionFormSection(title: "기본 정보") {
            PopupSubmissionTextInput(
                title: "지번 주소",
                placeholder: "도로명 주소와 다를 때 입력",
                text: $store.address,
                isRequired: store.mode == .adminReview
            )

            HStack(spacing: 10) {
                PopupSubmissionTextInput(
                    title: "오픈 시간",
                    placeholder: "10:00",
                    text: $store.openTime,
                    keyboardType: .numbersAndPunctuation
                )

                PopupSubmissionTextInput(
                    title: "마감 시간",
                    placeholder: "20:00",
                    text: $store.closeTime,
                    keyboardType: .numbersAndPunctuation
                )
            }

            HStack(spacing: 10) {
                PopupSubmissionTextInput(
                    title: "위도",
                    placeholder: "37.544",
                    text: $store.latitude,
                    isRequired: store.mode == .adminReview,
                    keyboardType: .decimalPad
                )

                PopupSubmissionTextInput(
                    title: "경도",
                    placeholder: "127.055",
                    text: $store.longitude,
                    isRequired: store.mode == .adminReview,
                    keyboardType: .decimalPad
                )
            }

            PopupSubmissionTextInput(
                title: "인스타그램 URL",
                placeholder: "https://instagram.com/p/...",
                text: $store.instaPostUrl,
                keyboardType: .URL,
                textInputAutocapitalization: .never
            )
        }
    }

    var adminSection: some View {
        PopupSubmissionFormSection(title: "관리자 입력") {
            PopupSubmissionMediaTypePicker(selected: $store.mediaType)

            PopupSubmissionTextInput(
                title: "인스타그램 Post ID",
                placeholder: "선택 입력",
                text: $store.instaPostId
            )

            PopupSubmissionTextInput(
                title: "Geocoding Query",
                placeholder: "선택 입력",
                text: $store.geocodingQuery
            )

            Toggle(isOn: $store.isActive) {
                PopupSubmissionFieldTitle(title: "활성화 여부", isRequired: true)
            }
            .tint(Color.mainOrange)
        }
    }
}

private struct PopupSubmissionFormSection<Content: View>: View {
    let title: String
    let isRequired: Bool
    private let content: Content

    init(
        title: String,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.mainBlack)

                if isRequired {
                    Text("*")
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainOrange)
                }
            }

            VStack(spacing: 14) {
                content
            }
        }
    }
}

private struct PopupSubmissionTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired = false
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization? = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if title.isEmpty == false {
                PopupSubmissionFieldTitle(title: title, isRequired: isRequired)
            }

            TextField("", text: $text)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainBlack)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .autocorrectionDisabled(keyboardType == .URL)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.subWhite)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.scdream(.medium, size: 12))
                            .foregroundStyle(Color.mainGray2)
                            .padding(.horizontal, 14)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mainGray3, lineWidth: 0.8)
                }
        }
    }
}

private struct PopupSubmissionTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupSubmissionFieldTitle(title: title, isRequired: isRequired)

            TextEditor(text: $text)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainBlack)
                .frame(minHeight: 116)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.subWhite)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.scdream(.medium, size: 12))
                            .foregroundStyle(Color.mainGray2)
                            .padding(.top, 18)
                            .padding(.leading, 14)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mainGray3, lineWidth: 0.8)
                }
        }
    }
}

private struct PopupSubmissionCategoryPicker: View {
    let title: String
    let categories: [Recommend]
    let selectedIds: [Int]
    var isRequired = false
    let onToggle: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupSubmissionFieldTitle(title: title, isRequired: isRequired)

            if categories.isEmpty {
                Text("추천 카테고리를 불러오는 중입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color.subWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.mainGray3, lineWidth: 0.8)
                    }
            } else {
                SearchFlowLayout {
                    ForEach(categories) { category in
                        Button {
                            onToggle(category.id)
                        } label: {
                            Text(category.recommendName)
                                .font(.scdream(.medium, size: 12))
                                .foregroundStyle(selectedIds.contains(category.id) ? Color.mainOrange : Color.mainGray)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 34)
                                .background {
                                    Capsule()
                                        .fill(selectedIds.contains(category.id) ? Color.categoryOrange : Color.subWhite)
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(selectedIds.contains(category.id) ? Color.mainOrange : Color.mainGray3, lineWidth: 1)
                                }
                        }
                        .buttonStyle(PressableButtonStyle())
                        .padding(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct PopupSubmissionMediaTypePicker: View {
    @Binding var selected: Popup.MediaType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupSubmissionFieldTitle(title: "미디어 타입", isRequired: true)

            HStack(spacing: 8) {
                ForEach([Popup.MediaType.image, .carousel, .video], id: \.self) { mediaType in
                    Button {
                        selected = mediaType
                    } label: {
                        Text(title(for: mediaType))
                            .font(.scdream(.medium, size: 12))
                            .foregroundStyle(selected == mediaType ? Color.subWhite : Color.mainGray)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(selected == mediaType ? Color.mainOrange : Color.subWhite)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(selected == mediaType ? Color.mainOrange : Color.mainGray3, lineWidth: 1)
                            }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private func title(for mediaType: Popup.MediaType) -> String {
        switch mediaType {
        case .image:
            "IMAGE"
        case .carousel:
            "CAROUSEL"
        case .video:
            "VIDEO"
        }
    }
}

private struct PopupSubmissionDateInput: View {
    let title: String
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupSubmissionFieldTitle(title: title, isRequired: true)

            HStack(spacing: 10) {
                DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("-")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)

                DatePicker("종료일", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.subWhite)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mainGray3, lineWidth: 0.8)
            }
        }
    }
}

private struct PopupSubmissionFieldTitle: View {
    let title: String
    let isRequired: Bool

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainBlack)

            if isRequired {
                Text("*")
                    .font(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainOrange)
            }
        }
    }
}
