//
//  MapSortButton.swift
//  PopPang
//
//  Created by 김동현 on 11/8/25.
//

import SwiftUI

struct MapSortButtonPreview: View {
    @State private var showRegionSheet: Bool = false
    @State var selectedOption: MapSortButton.SortOption = .closest
    var body: some View {
        VStack {
            MapSortButton(selectedOption: $selectedOption) {
                showRegionSheet.toggle()
            }
        }
        .sheet(isPresented: $showRegionSheet, onDismiss: {}) {
            MapSortButtonSheet(selectedOption: $selectedOption) {
                
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    MapSortButtonPreview()
}

struct MapSortButton: View {
    enum SortOption: String, CaseIterable {
        case closest        = "CLOSEST"
        case newest         = "NEWEST"
        case closingSoon    = "CLOSING_SOON"
        case mostFavorited  = "MOST_FAVORITED"
        case mostViewed     = "MOST_VIEWED"
        
        var title: String {
            switch self {
            case .closest: return "가까운순"
            case .newest: return "최신순"
            case .closingSoon: return "마감순"
            case .mostFavorited: return "찜순"
            case .mostViewed: return "조회순"
            }
        }
    }
    @Binding var selectedOption: SortOption
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
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
            .background(Color.subWhite)
            .cornerRadius(17)
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(lineWidth: 1)
                    .foregroundColor(Color.mainGray5)
            }
        }
    }
}

// MARK: - Sheet
struct MapSortButtonSheet: View {
    @Binding var selectedOption: MapSortButton.SortOption
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - 상단
            HStack(spacing: 0) {
                Text("정렬")
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.bold, size: 17))
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(.system(size: 21, weight: .regular))
                }
            }
            
            // MARK: - Body
            VStack(alignment: .leading, spacing: 10) {
                ForEach(MapSortButton.SortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                        onDismiss()
                    } label: {
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
            .padding(.top, 28)
            Spacer()
        }
        .padding(.top, 28)
        .padding(.horizontal, 28)
        .presentationDragIndicator(.visible)
    }
}
