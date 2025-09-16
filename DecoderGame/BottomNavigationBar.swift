//
//  BottomNavigationBar.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/15/25.
//


//
//  BottomNavigationBar.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct BottomNavigationBar: View {
    let currentPage: Int
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            ForEach([0, 1, 2], id: \.self) { pageIndex in
                pageIndicator(for: pageIndex)
            }
            Spacer()
        }
        .frame(height: 55)
        .background(LinearGradient.bottomSwipeBarGradient)
    }
    
    private func pageIndicator(for pageIndex: Int) -> some View {
        Image(systemName: currentPage == pageIndex ? "smallcircle.filled.circle.fill" : "smallcircle.filled.circle")
            .font(.system(size: currentPage == pageIndex ? 14 : 12))
            .foregroundColor(.white)
            .padding(.leading, pageIndex == 0 ? 30 : 0)
            .padding(.trailing, pageIndex == 2 ? 30 : 0)
    }
}