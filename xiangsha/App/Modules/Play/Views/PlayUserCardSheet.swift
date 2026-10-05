//
//  PlayUserCardSheet.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/5.
//  关联决策：D029 扩展 · 用户自定义玩啥卡
//

import SwiftUI

/// 用户自定义玩啥卡 sheet
///
/// 字段：
/// - title（必填）
/// - emoji（可选）
/// - costLevel（Free/Low/High）
struct PlayUserCardSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var emoji: String = ""
    @State private var costLevel: CostLevel = .free

    let onSave: (String, String, CostLevel) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    TextField("点子（必填）", text: $title)
                    TextField("emoji（可选）", text: $emoji)
                }

                Section("费用档（D061）") {
                    Picker("费用", selection: $costLevel) {
                        ForEach(CostLevel.allCases, id: \.self) { cost in
                            Text("\(cost.emoji) \(cost.title)").tag(cost)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("➕ 加点子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(
                            title.trimmingCharacters(in: .whitespaces),
                            emoji.isEmpty ? "🎮" : emoji,
                            costLevel
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
