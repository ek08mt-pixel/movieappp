import SwiftUI

struct AchievementDetailView: View {
    let achievement: AchievementDefinition
    let progress: AchievementProgress
    let userRank: UserRankData
    @Environment(\.dismiss) var dismiss
    
    var currentTier: AchievementTier? {
        achievement.currentTier(progress: progress.currentValue)
    }
    
    var nextTier: AchievementTier? {
        achievement.nextTier(progress: progress.currentValue)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Close button
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Badge
                        VStack(spacing: 16) {
                            Text(currentTier?.icon ?? achievement.icon)
                                .font(.system(size: 80))
                                .shadow(color: userRank.currentRank.color.opacity(0.4), radius: 30)
                            
                            Text(currentTier?.name ?? achievement.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let tier = currentTier {
                                Text("Level \(tier.tier)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(userRank.currentRank.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(userRank.currentRank.color.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        // Conditions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Điều kiện")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(achievement.tiers) { tier in
                                HStack(spacing: 12) {
                                    if progress.unlockedTiers.contains(tier.tier) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.green)
                                    } else if tier.tier == (nextTier?.tier ?? -1) {
                                        Image(systemName: "circle.dotted")
                                            .font(.system(size: 18))
                                            .foregroundColor(.orange.opacity(0.7))
                                    } else if tier.tier > (nextTier?.tier ?? Int.max) || nextTier == nil {
                                        Image(systemName: "circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.gray.opacity(0.3))
                                    } else {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(tier.icon) \(tier.name)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(
                                                progress.unlockedTiers.contains(tier.tier) ? .white :
                                                    tier.tier == (nextTier?.tier ?? -1) ? .orange.opacity(0.8) : .gray.opacity(0.5)
                                            )
                                        Text(tier.description)
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    if progress.unlockedTiers.contains(tier.tier) {
                                        Text("✔")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            progress.unlockedTiers.contains(tier.tier) ?
                                                .white.opacity(0.05) : .white.opacity(0.02)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Progress to next tier
                        if let next = nextTier {
                            VStack(spacing: 12) {
                                Text("Tiến độ lên \(next.name)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(white: 0.2))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [userRank.currentRank.color, userRank.currentRank.color.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * next.progress(current: progress.currentValue), height: 8)
                                            .animation(.spring(response: 1, dampingFraction: 0.6), value: progress.currentValue)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(progress.currentValue) / \(next.requirement)")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 60)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}