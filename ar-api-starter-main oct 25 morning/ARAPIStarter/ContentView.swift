//
//  ContentView.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State var viewModel: ViewModel

    var body: some View {
        ZStack {
            // AR View.
            ARViewContainer(viewModel: viewModel)

            // Reset button.
            Button {
                viewModel.uiSignal.send(.spawnParasite)
            } label: {
                Label("Reset", systemImage: "gobackward")
                    .font(.system(.title))
                    .foregroundColor(.white)
                    .labelStyle(IconOnlyLabelStyle())
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()

            // Slider.
            VStack {
                Spacer()
                
                Slider(value: $viewModel.sliderValue)
                    .padding(.horizontal)
                Text("\(viewModel.sliderValue)")
            }
            .padding(.vertical, 80)
        }
    }
}

#Preview {
    ContentView(viewModel: ViewModel())
}
