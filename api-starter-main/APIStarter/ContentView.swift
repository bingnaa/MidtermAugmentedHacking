//
//  ContentView.swift
//  APIStarter
//
//  Created by Nien Lam on 10/12/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let viewModel = ViewModel()
    let viewControl = ViewController()

    var body: some View {
        VStack {
            // Access date string in view model.
            Text(viewModel.dateString)
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
