import Compound
import DSKit
import Domain
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct PopupReportFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var compound: PopupReportFeatureCompound
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    private let onDismiss: (() -> Void)?

    public init(onDismiss: (() -> Void)? = nil) {
        _compound = State(wrappedValue: PopupReportFeatureCompound())
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    requiredSection
                    optionalSection
                    imageSection
                }
                .padding(.horizontal, .contentPadding)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .background(Color.mainGray4.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            submitButton
        }
        .compoundOnLoad(compound, .onAppear)
        .onChange(of: selectedPhotoItems) { _, items in
            Task {
                await loadImages(from: items)
            }
        }
        .alert("제출 실패", isPresented: errorPresentedBinding) {
            Button("확인") {
                compound.send(.dismissError)
            }
        } message: {
            Text(compound.state.errorMessage ?? "")
        }
        .alert("제보 완료", isPresented: successPresentedBinding) {
            Button("확인") {
                compound.send(.dismissSuccess)
                close()
            }
        } message: {
            Text("팝업 제보가 등록되었습니다.")
        }
    }
}

private extension PopupReportFeatureView {
    var navigationBar: some View {
        CustomNavigationBar {
            Button {
                close()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.mainBlack)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()

            Text("팝업 제보하기")
                .font(.scdream(.bold, size: 17))
                .foregroundStyle(Color.mainBlack)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .background(Color.subWhite)
    }

    var requiredSection: some View {
        PopupReportFormSection(title: "필수 입력") {
            PopupReportTextInput(
                title: "팝업명",
                placeholder: "팝업명을 입력해 주세요",
                text: binding(.name),
                isRequired: true
            )

            PopupReportDateInput(
                title: "운영 기간",
                startDate: Binding(
                    get: { compound.state.startDate },
                    set: { compound.send(.startDateChanged($0)) }
                ),
                endDate: Binding(
                    get: { compound.state.endDate },
                    set: { compound.send(.endDateChanged($0)) }
                )
            )

            PopupReportTextInput(
                title: "도로명 주소",
                placeholder: "예: 서울 성동구 성수이로 00",
                text: binding(.roadAddress),
                isRequired: true
            )

            PopupReportTextInput(
                title: "지역",
                placeholder: "예: 서울",
                text: binding(.region),
                isRequired: true
            )

            PopupReportTextEditor(
                title: "팝업 소개",
                placeholder: "팝업의 주요 내용과 참고할 정보를 입력해 주세요",
                text: binding(.captionSummary),
                isRequired: true
            )
        }
    }

    var optionalSection: some View {
        PopupReportFormSection(title: "선택 입력") {
            PopupReportTextInput(
                title: "지번 주소",
                placeholder: "도로명 주소와 다를 때 입력",
                text: binding(.address)
            )

            HStack(spacing: 10) {
                PopupReportTextInput(
                    title: "오픈 시간",
                    placeholder: "10:00",
                    text: binding(.openTime),
                    keyboardType: .numbersAndPunctuation
                )

                PopupReportTextInput(
                    title: "마감 시간",
                    placeholder: "20:00",
                    text: binding(.closeTime),
                    keyboardType: .numbersAndPunctuation
                )
            }

            HStack(spacing: 10) {
                PopupReportTextInput(
                    title: "위도",
                    placeholder: "37.544",
                    text: binding(.latitude),
                    keyboardType: .decimalPad
                )

                PopupReportTextInput(
                    title: "경도",
                    placeholder: "127.055",
                    text: binding(.longitude),
                    keyboardType: .decimalPad
                )
            }

            PopupReportTextInput(
                title: "인스타그램 URL",
                placeholder: "https://instagram.com/p/...",
                text: binding(.instaPostUrl),
                keyboardType: .URL,
                textInputAutocapitalization: .never
            )

            PopupReportTextInput(
                title: "게시물 ID",
                placeholder: "URL에서 자동 추출되며 직접 입력도 가능",
                text: binding(.instaPostId),
                textInputAutocapitalization: .never
            )

            PopupReportCategoryPicker(
                title: "추천 카테고리",
                categories: compound.state.recommendList,
                selectedIds: compound.state.selectedRecommendIds
            ) { id in
                compound.send(.categoryToggled(id))
            }
        }
    }

    var imageSection: some View {
        PopupReportFormSection(title: "이미지") {
            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .semibold))
                    Text("이미지 선택")
                        .font(.scdream(.medium, size: 13))
                    Spacer()
                    Text("\(compound.state.images.count)/10")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                }
                .foregroundStyle(Color.mainOrange)
                .frame(height: 48)
                .padding(.horizontal, 14)
                .background(Color.subWhite)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mainOrange, lineWidth: 1)
                }
            }
            .buttonStyle(PressableButtonStyle())

            if compound.state.images.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(compound.state.images) { image in
                            PopupReportImageThumbnail(image: image) {
                                compound.send(.imageRemoved(image.id))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    var submitButton: some View {
        VStack(spacing: 0) {
            Divider()

            MainOrangeButton(
                buttonTitle: compound.state.isSubmitting ? "제출 중" : "제보하기",
                height: 56
            ) {
                compound.send(.submit)
            }
            .disabled(compound.state.isSubmitEnabled == false)
            .opacity(compound.state.isSubmitEnabled ? 1 : 0.45)
            .padding(.horizontal, .contentPadding)
            .padding(.vertical, 12)
            .background(Color.subWhite)
        }
    }

    var errorPresentedBinding: Binding<Bool> {
        Binding(
            get: { compound.state.errorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    compound.send(.dismissError)
                }
            }
        )
    }

    var successPresentedBinding: Binding<Bool> {
        Binding(
            get: { compound.state.isSubmitted },
            set: { isPresented in
                if isPresented == false {
                    compound.send(.dismissSuccess)
                }
            }
        )
    }

    func binding(_ field: PopupReportTextField) -> Binding<String> {
        Binding(
            get: { compound.state.text(for: field) },
            set: { compound.send(.textChanged(field, $0)) }
        )
    }

    func close() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    func loadImages(from items: [PhotosPickerItem]) async {
        do {
            var images: [PopupReportSelectedImage] = []

            for (index, item) in items.enumerated() {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let contentType = item.supportedContentTypes.first { $0.conforms(to: .image) }
                let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
                let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"

                images.append(
                    PopupReportSelectedImage(
                        data: data,
                        fileName: "popup-report-\(index + 1).\(fileExtension)",
                        mimeType: mimeType
                    )
                )
            }

            compound.send(.imagesLoaded(images))
        } catch {
            compound.send(.imageLoadingFailed(error.localizedDescription))
        }
    }
}

private struct PopupReportFormSection<Content: View>: View {
    let title: String
    private let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            VStack(spacing: 14) {
                content
            }
        }
    }
}

private struct PopupReportTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired = false
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization? = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupReportFieldTitle(title: title, isRequired: isRequired)

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

private struct PopupReportTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupReportFieldTitle(title: title, isRequired: isRequired)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainBlack)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 116)

                if text.isEmpty {
                    Text(placeholder)
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray2)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.subWhite)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mainGray3, lineWidth: 0.8)
            }
        }
    }
}

private struct PopupReportCategoryPicker: View {
    let title: String
    let categories: [Recommend]
    let selectedIds: [Int]
    let onToggle: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupReportFieldTitle(title: title, isRequired: false)

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
                        CategoryButton(
                            title: category.recommendName,
                            isSelected: selectedIds.contains(category.id)
                        ) {
                            onToggle(category.id)
                        }
                        .padding(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }
        }
    }
}

private struct PopupReportDateInput: View {
    let title: String
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PopupReportFieldTitle(title: title, isRequired: true)

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

private struct PopupReportFieldTitle: View {
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

private struct PopupReportImageThumbnail: View {
    let image: PopupReportSelectedImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mainGray5)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Color.mainGray)
                    }
            }

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.subWhite)
                    .frame(width: 22, height: 22)
                    .background(Color.subBlack.opacity(0.7))
                    .clipShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .padding(5)
        }
    }
}
