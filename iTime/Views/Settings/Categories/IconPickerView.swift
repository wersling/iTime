//
//  IconPickerView.swift
//  iTime
//
//  Created by Linus Torvalds on 2025/11/21.
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    let columns = [GridItem(.adaptive(minimum: 50))]
    
    var filteredIcons: [String] {
        if searchText.isEmpty {
            return SFSymbols.all
        } else {
            return SFSymbols.all.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredIcons, id: \.self) { iconName in
                        Button {
                            selection = iconName
                            dismiss()
                        } label: {
                            Image(systemName: iconName)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                        .opacity(selection == iconName ? 1 : 0)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: selection == iconName ? 2 : 0)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索图标")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    IconPickerView(selection: .constant("star.fill"))
}

