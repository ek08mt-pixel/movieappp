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
    
    var tierColor: Color {
        guard let tier = currentTier else { return .gray }
        let ratio = Double(tier.tier) / Double(max(achievement.tiers.count, 1))
        return Color(red: 0.3 + 0.7 * ratio, green: 0.7 - 0.4 * ratio, blue: 0.9 - 0.3 * ratio)
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
                                Text("✕")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Badge
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(tierColor.opacity(0.2))
                                    .frame(width: 140, height: 140)
                                    .blur(radius: 30)
                                
                                AchievementBadgeView(
                                    tier: currentTier?.tier ?? 1,
                                    maxTier: achievement.tiers.count,
                                    size: 100
                                )
                                
                                if let tier = currentTier, tier.tier >= achievement.tiers.count {
                                    Text("✦")
                                        .font(.system(size: 26))
                                        .foregroundColor(tierColor)
                                        .offset(y: -60)
                                }
                            }
                            
                            Text(currentTier?.name ?? achievement.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(achievement.title)
                                .font(.system(size: 14))
                                .foregroundColor(tierColor)
                                .tracking(1)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(tierColor.opacity(0.12)))
                            
                            if let tier = currentTier {
                                Text(tier.vibe)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(tierColor.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        // Conditions
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ĐIỀU KIỆN MỞ KHÓA")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(2)
                            
                            ForEach(achievement.tiers) { tier in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(tierColorForTier(tier).opacity(progress.unlockedTiers.contains(tier.tier) ? 0.15 : 0.03))
                                            .frame(width: 40, height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(tierColorForTier(tier).opacity(progress.unlockedTiers.contains(tier.tier) ? 0.4 : 0.08), lineWidth: 1)
                                            )
                                        
                                        if progress.unlockedTiers.contains(tier.tier) {
                                            Text("✓")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(tierColorForTier(tier))
                                        } else {
                                            Text("○")
                                                .font(.system(size: 18, weight: .light))
                                                .foregroundColor(.gray.opacity(0.4))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tier.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(progress.unlockedTiers.contains(tier.tier) ? .white : .gray.opacity(0.5))
                                        Text(tier.description)
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                        if !tier.vibe.isEmpty && progress.unlockedTiers.contains(tier.tier) {
                                            Text(tier.vibe)
                                                .font(.system(size: 10))
                                                .foregroundColor(tierColorForTier(tier).opacity(0.7))
                                                .italic()
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if progress.unlockedTiers.contains(tier.tier) {
                                        Text("✓")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(tierColorForTier(tier))
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(progress.unlockedTiers.contains(tier.tier) ? .white.opacity(0.03) : .clear)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Progress to next
                        if let next = nextTier {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Tiến độ lên")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                    Text(next.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(tierColor)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color(white: 0.18))
                                            .frame(height: 10)
                                        
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(
                                                LinearGradient(
                                                    colors: [tierColor, tierColor.opacity(0.4)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * next.progress(current: progress.currentValue), height: 10)
                                            .animation(.spring(response: 1, dampingFraction: 0.6), value: progress.currentValue)
                                    }
                                }
                                .frame(height: 10)
                                
                                Text("\(progress.currentValue) / \(next.requirement)")
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Text(next.vibe)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(tierColor.opacity(0.15), lineWidth: 0.5)
                                    )
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
    
    func tierColorForTier(_ tier: AchievementTier) -> Color {
        let ratio = Double(tier.tier) / Double(max(achievement.tiers.count, 1))
        return Color(red: 0.3 + 0.7 * ratio, green: 0.7 - 0.4 * ratio, blue: 0.9 - 0.3 * ratio)
    }
}