//
//  SortButton.swift
//  PopPang
//
//  Created by 김동현 on 10/28/25.
//

import SwiftUI

// MARK: - 프리뷰
struct SortButtonView: View {
    @State private var showRegionSheet: Bool = false
    @State private var selectedOption: SortButton.SortOption = .favorite
    
    var body: some View {
        VStack {
            SortButton(selectedOption: $selectedOption) {
                showRegionSheet.toggle()
            }
        }
        .sheet(isPresented: $showRegionSheet,
               onDismiss: {
            print("시트 닫힘 — 선택된 정렬 옵션: \(selectedOption.rawValue)")
        }) {
            RegionButtonSheet(selectedOption: $selectedOption)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - 버튼
struct SortButton: View {
    enum SortOption: String, CaseIterable {
        case favorite
        case distance
        
        var title: String {
            switch self {
            case .favorite: return "찜순"
            case .distance: return "가까운순"
            }
        }
    }
    
    @Binding var selectedOption: SortOption
    let fgColor: Color = .mainGray5
    let bgColor: Color = .subWhite
    var action: () -> Void
    
    var body: some View {
        Button {
             action()
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.title)
                    .ppStyleFont(.scdream(.light, size: 10))
                    .foregroundStyle(Color.mainGray)
                   
                Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.mainGray)
                
                  
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
             .frame(width: 80)
            .background(bgColor)
            .cornerRadius(17)
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(lineWidth: 1)
                    .foregroundColor(fgColor)
            }
        }
    }
}

// MARK: - 시트
struct RegionButtonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: SortButton.SortOption
    
    let backFont: Font = .system(size: 17, weight: .bold)
    let titlefont: Font = .system(size: 24, weight: .medium)
    let buttonFont: Font = .system(size: 21, weight: .regular)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - 상단
            HStack(spacing: 0) {
                Text("정렬")
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.bold, size: 17))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(backFont)
                }
            }
            
            // MARK: - body
            VStack(alignment: .leading, spacing: 10) {
                ForEach(SortButton.SortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option // 부모의 선택 상태 갱신
                        dismiss()
                    } label: {
                        HStack(spacing: 15) {
                            Image(selectedOption == option ? "circle_filled" : "circle")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(selectedOption == option ? .orange : .gray)
                            Text(option.title)
                                .foregroundStyle(Color.mainBlack)
                                .ppStyleFont(.scdream(.regular, size: 15))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40)
                    }
                }
            }
            .padding(.top, 28)
            
            Spacer()
        }
        .padding(.top, 28)
        .padding(.horizontal, 28)
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    @Previewable @State var selectedOption: SortButton.SortOption = .favorite
    
    SortButtonView()
    
//    RegionButtonSheet(selectedOption: $selectedOption)
}
