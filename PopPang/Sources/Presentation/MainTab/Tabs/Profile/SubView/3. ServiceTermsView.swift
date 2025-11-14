//
//  ServiceTerms.swift
//  PopPang
//
//  Created by 김동현 on 11/14/25.
//

import SwiftUI

struct ServiceTermsView: View {
    var body: some View {
        WebView(url: URL(string: Constants.URL.serviceTerms))
    }
}

#Preview {
    ServiceTermsView()
}
