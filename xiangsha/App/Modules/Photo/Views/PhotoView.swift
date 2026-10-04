//
//  PhotoView.swift
//  xiangsha
//
//  Created by 风小孩 on 2026/10/4.
//  模块 D · 拍啥 Tab
//

import SwiftUI
import SwiftData

/// 模块 D · 拍啥 Tab 根视图
struct PhotoView: View {
    @Query(filter: #Predicate<DecisionScene> { $0.typeRaw == "photo" })
    private var photoScenes: [DecisionScene]

    @Query(filter: #Predicate<UserProfile> { _ in true })
    private var profiles: [UserProfile]

    @State private var viewModel = PhotoViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let scene = photoScenes.first {
                    PhotoContentView(scene: scene, pools: scene.cardPools, profile: profiles.first, viewModel: viewModel)
                } else {
                    PlaceholderTabView(sceneType: .photo)
                }
            }
            .background(Color.theme.background)
            .navigationTitle(DecisionSceneType.photo.title)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.scene = photoScenes.first
            viewModel.selectedPool = photoScenes.first?.cardPools.first
            if let profile = profiles.first {
                viewModel.userProfileSnapshot = UserProfileSnapshot(
                    from: profile,
                    recentStyles7d: [],
                    lastMealOfToday: nil,
                    historyAggregate: .empty
                )
            }
        }
    }
}

private struct PhotoContentView: View {
    let scene: DecisionScene
    let pools: [CardPool]
    let profile: UserProfile?
    @Bindable var viewModel: PhotoViewModel

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            VStack(spacing: ThemeSpacing.xs) {
                Text(scene.icon).font(.system(size: 56))
                Text(viewModel.greetingText)
                    .font(Font.theme.title3)
                    .foregroundStyle(Color.theme.textPrimary)
            }
            .padding(.top, ThemeSpacing.md)

            if let result = viewModel.lastResult {
                PhotoDrawResultView(result: result)
            } else if let error = viewModel.error {
                PhotoDrawErrorView(error: error, onDismiss: { viewModel.dismissError() })
            } else {
                PhotoEmptyStateView()
            }

            Spacer()

            Button(action: {
                if viewModel.lastResult != nil {
                    viewModel.accept()
                } else {
                    Task { await viewModel.draw() }
                }
            }) {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(Color.theme.textOnPrimary) }
                    Text(viewModel.primaryButtonText).font(Font.theme.buttonLarge)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.theme.accent, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                .foregroundStyle(Color.theme.textOnPrimary)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal)

            if viewModel.showsSecondaryActions {
                HStack(spacing: ThemeSpacing.md) {
                    SecondaryPhotoButton(title: "换姿势 🔁", action: { Task { await viewModel.redraw() } })
                    SecondaryPhotoButton(title: "算了", action: { viewModel.reject() })
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.bottom, ThemeSpacing.lg)
    }
}

private struct PhotoDrawResultView: View {
    let result: DrawResult

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ThemeRadius.lg)
                    .fill(LinearGradient(
                        colors: [Color.theme.accentSubtle, Color.theme.accent.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 360)
                    .shadow(color: .black.opacity(0.05), radius: ThemeShadow.md)

                VStack(spacing: ThemeSpacing.md) {
                    Text(result.card.emoji ?? "📸").font(.system(size: 96))

                    Text(result.card.title)
                        .font(Font.theme.title1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)

                    if let category = result.card.category {
                        Text("·\(category)·")
                            .font(Font.theme.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("拍啥姿势：\(result.card.title)")
        }
    }
}

private struct PhotoDrawErrorView: View {
    let error: DrawEngineError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.warning)
            Text("歇够了？加点新内容吧")
                .font(Font.theme.title3)
            Button("知道了", action: onDismiss).buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
    }
}

private struct PhotoEmptyStateView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Text("🦊").font(.system(size: 96))
            Text("准备拍点啥")
                .font(Font.theme.title3)
                .foregroundStyle(Color.theme.textPrimary)
            Text("v1 用 emoji + 文字描述，v1.1+ 上真实图")
                .font(Font.theme.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct SecondaryPhotoButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.theme.button)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.theme.surface, in: RoundedRectangle(cornerRadius: ThemeRadius.md))
                .foregroundStyle(Color.theme.textPrimary)
        }
    }
}

#Preview {
    PhotoView()
        .modelContainer(for: [
            DecisionScene.self, CardPool.self, Card.self,
            DrawRecord.self, UserProfile.self, Favorite.self, UserTaskRecord.self
        ], inMemory: true)
}