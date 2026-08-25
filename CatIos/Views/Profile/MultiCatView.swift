//
//  MultiCatView.swift
//  CatIos
//
//  Compatibility shim — use MultiPetView for new code.

import SwiftUI

struct MultiCatView: View {
    var body: some View {
        MultiPetView()
    }
}

#Preview {
    NavigationStack {
        MultiCatView()
            .environmentObject(PetManager.shared)
    }
}
