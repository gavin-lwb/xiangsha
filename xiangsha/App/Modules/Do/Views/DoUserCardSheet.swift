//
//  DoUserCardSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D068-D076 扩展 · 用户自定义任务
//

import SwiftUI

/// 用户自定义任务 sheet（做啥模块）
///
/// 字段：
/// - title（必填）
/// - emoji（可选）
/// - type（micro 微任务 / rescue 急救）
struct DoUserCardSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var emoji: String = ""
    @State private var type: String = "micro"

    let onSave: (String, String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("任务（必填）", text: $title)
                    TextField("emoji（可选）", text: $emoji)
                }

                Section("类型") {
                    Picker("类型", selection: $type) {
                        Text("微任务").tag("micro")
                        Text("急救").tag("rescue")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("➕ 加任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(
                            title.trimmingCharacters(in: .whitespaces),
                            emoji.isEmpty ? "✅" : emoji,
                            type
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
