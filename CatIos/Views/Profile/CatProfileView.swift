//
//  CatProfileView.swift
//  CatEmotionAI
//
//  Compatibility shim — use PetProfileView for new code.

import SwiftUI

struct CatProfileView: View {
    var body: some View {
        PetProfileView()
    }
}

#Preview {
    CatProfileView()
}
