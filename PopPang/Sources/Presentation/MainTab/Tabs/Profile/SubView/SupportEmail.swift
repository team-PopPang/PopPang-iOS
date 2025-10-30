//
//  SupportEmail.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import SwiftUI

struct SupportEmail {
    let toAddress: String
    let title: String
    let messageHeader: String
    var body: String {
        """
        \(messageHeader)
    """
    }
    
    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted {
                print("""
                This device does not support email
                \(body)
                """)
            }
        }
    }

}
