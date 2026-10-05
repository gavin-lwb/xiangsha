//
//  PhotoUserCardSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D080-D086 扩展 · 用户自定义姿势
//

import SwiftUI

/// 用户自定义姿势 sheet（拍啥模块）
///
/// 字段：
/// - title（必填）
/// - emoji（可选）
struct PhotoUserCardSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var emoji: String = ""

    let onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("姿势名（必填）", text: $title)
                    TextField("emoji（可选）", text: $emoji)
                }
            }
            .navigationTitle("➕ 加姿势")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(
                            title.trimmingCharacters(in: .whitespaces),
                            emoji.isEmpty ? "📸" : emoji
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
