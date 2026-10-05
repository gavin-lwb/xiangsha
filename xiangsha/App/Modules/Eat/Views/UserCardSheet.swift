//
//  UserCardSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D029 扩展 · 用户自定义卡 UI（Card.isUserCreated = true）
//

import SwiftUI

/// 用户自定义卡 sheet
///
/// 让用户加自己的卡（被标记 isUserCreated = true）：
/// - title（必填）
/// - emoji（可选）
/// - scenario（HomeCook / Takeout / EatIn）
/// - category（字符串）
///
/// onSave 回调把数据传回 caller（EatViewModel.createUserCard）
struct UserCardSheet: View {
    let defaultPool: CardPool?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var emoji: String = ""
    @State private var scenario: EatScenario = .takeout
    @State private var category: String = "lunch"

    let onSave: (String, String, EatScenario, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("菜名（必填）", text: $title)
                    TextField("emoji（可选）", text: $emoji)
                }

                Section("用餐场景") {
                    Picker("场景", selection: $scenario) {
                        ForEach(EatScenario.allCases, id: \.self) { s in
                            Text(s.title).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("时段") {
                    Picker("时段", selection: $category) {
                        Text("早餐").tag("breakfast")
                        Text("午餐").tag("lunch")
                        Text("下午茶").tag("tea")
                        Text("晚餐").tag("dinner")
                        Text("夜宵").tag("latenight")
                    }
                }
            }
            .navigationTitle("➕ 加卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(
                            title.trimmingCharacters(in: .whitespaces),
                            emoji.isEmpty ? "🍽️" : emoji,
                            scenario,
                            category
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
