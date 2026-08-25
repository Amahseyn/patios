//
//  CatSwitcherView.swift
//  CatIos
//
//  Compatibility shim — use PetSwitcherView for new code.

import SwiftUI

struct CatSwitcherView: View {
    @EnvironmentObject var catManager: CatManager
    @State private var showAddCatModal = false

    var body: some View {
        PetSwitcherView()
            .environmentObject(PetManager.shared)
    }
}
