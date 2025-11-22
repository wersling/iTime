//
//  CategorySelectionView.swift
//  iTime
//
//  Created by Linus Torvalds on 2025/11/21.
//

import SwiftUI
import SwiftData

struct CategorySelectionView: View {
    @Binding var selection: EventCategory?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \EventCategory.sortOrder) private var categories: [EventCategory]
    
    @State private var showManagement = false
    
    var body: some View {
        List {
            Section {
                Button {
                    showManagement = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("增加和管理分类")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Section("所有分类") {
                ForEach(categories) { category in
                    Button {
                        selection = category
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .frame(width: 30)
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selection?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择分类")
        .sheet(isPresented: $showManagement) {
            NavigationStack {
                CategoryManagementView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView(selection: .constant(nil))
            .modelContainer(for: EventCategory.self, inMemory: true)
    }
}
