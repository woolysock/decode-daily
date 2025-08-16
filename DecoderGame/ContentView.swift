//
//  ContentView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 11/24/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true

        var body: some View {
            Group {
                if isLoading {
                    LoadingView() //custom load screen goes here
                } else {
                    MainMenuView() // app content
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isLoading = false
                }
            }
        }
 //   var body: some View {
 //       MainMenuView()
 //   }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("TitleLoader-w")
                .resizable()
                .scaledToFit()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
