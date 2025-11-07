//
//  RegionButton.swift
//  PopPang
//
//  Created by 김동현 on 10/28/25.
//

import SwiftUI

// MARK: - Preview
struct RegionButtonView: View {
    @StateObject private var viewModel = RegionViewModel()
    @State private var showSheet = false
    
    var body: some View {
        VStack {
            RegionButton(text: viewModel.selectedRegion?.region ?? "전체") {
                showSheet.toggle()
            }
        }
        .sheet(isPresented: $showSheet) {
            RegionSheet(
                regions: viewModel.regions,
                selectedRegion: $viewModel.selectedRegion,
                selectedDistrict: $viewModel.selectedDistrict
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Button
struct RegionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {                             // 화살표 간격 -> 명시해야함
                Text(text)
                    .ppStyleFont(.scdream(.light, size: 10)) // 글자 폰트 light, 글자크기 10
                    .foregroundStyle(Color.mainGray)         // 글자 색상 #777777
                Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.mainGray)
            }
            .padding(.vertical, 8)                          // 상하 패딩 8
            .padding(.horizontal, 10)                       // 좌우 패딩 10
            .frame(width: 80)                               // 길이 고정 가로 80
            .background(Color.subWhite)                     // FFFFFF
            .cornerRadius(17)                               // 모서리 라운딩
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(lineWidth: 1)
                    .foregroundColor(Color.mainGray5)
            }
        }
    }
}

// MARK: - Sheet
struct RegionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let regions: [RegionList]
    @Binding var selectedRegion: RegionList?
    @Binding var selectedDistrict: String?
    
    let backFont: Font = .system(size: 17, weight: .bold)
    let titlefont: Font = .system(size: 24, weight: .medium)
    let buttonFont: Font = .scdream(.regular, size: 12)
    
    let rowHeight: CGFloat = 46
    let dividerHeight: CGFloat = 1.5
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("지역")
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
            
            // Divider
            Rectangle()
                .frame(height: dividerHeight)
                .foregroundStyle(Color.mainGray3)
                .padding(.top, 30)
            
            HStack(spacing: 0) {
                
                // 좌측: 지역 목록
                List(regions) { region in
                    
                    VStack(spacing: 0) {
                        Button {
                            selectedRegion = region
                            selectedDistrict = region.districtList.first
                        } label: {
                            HStack(spacing: 0) {
                                Spacer()
                                Text(region.region)
                                    .foregroundStyle(selectedRegion == region ? Color.mainOrange : Color.mainGray)
                                    .font(buttonFont)
                                Spacer()
                            }
                        }
                        .frame(height: rowHeight) // 각 요소 높이
                    }
                    .listRowBackground(selectedRegion == region ? Color.subWhite : Color.mainGray4)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden) // 기본 구분선 제거
                }
                // 리스트 너비
                .frame(width: 65)
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                
                Divider()
                
                // 우측: 구 목록
                if let selected = selectedRegion {
                    List(selected.districtList, id: \.self) { district in
                        VStack(spacing: 0) {
                            Button {
                                selectedDistrict = district
                                dismiss()
                            } label: {
                                HStack(spacing: 0) {
                                    Text(district)
                                        .foregroundStyle(selectedDistrict == district ? Color.mainOrange : .primary)
                                        .font(buttonFont)
                                        .padding(.leading, 20)
                                    Spacer()
                                }
                            }
                            .frame(height: 46)
                            
                            // Divider
                            Divider()
                                .padding(.leading, 0)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden) // 기본 구분선 제거
                    }
                    .listStyle(.plain)
                }
            }
            .frame(height: CGFloat(regions.count) * (rowHeight))
            
            // Divider
            Rectangle()
                .frame(height: dividerHeight)
                .foregroundStyle(Color.mainGray3)
            
            Spacer()
        }
        .padding(.top, 28)
        .padding(.horizontal, 28)
        .presentationDragIndicator(.visible)
    }
}

final class RegionViewModel: ObservableObject {
    
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    init() {
        Task {
            await fetchRegions()
        }
    }
    
    func fetchRegions() async {
        // ⏳ 네트워크 대신 목업 데이터 (비동기 시뮬레이션)
        // try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 지연
        
        let mockData: [RegionListDTO] = [
 
        ]
        
        let mapped = mockData.map { $0.toEntity() }
        
        await MainActor.run {
            self.regions = mapped
            if let first = mapped.first {
                self.selectedRegion = first
                self.selectedDistrict = first.districtList.first
            }
        }
    }
}


#Preview {
    RegionButtonView()
}

