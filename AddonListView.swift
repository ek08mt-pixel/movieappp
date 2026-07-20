import SwiftUI

struct AddonListView: View {
    @StateObject private var manager = AddonManager.shared
    @State private var showAddSheet = false
    @State private var addonURL = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isTestingAddon: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                        Spacer()
                        Text("🧩 Add-ons")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        Spacer()
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    // Community Addons Button
                    Button {
                        addonURL = "https://stremio-addons.com"
                        showAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                            Text("Tìm addon cộng đồng")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.4)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    
                    // Installed Addons
                    if manager.addons.isEmpty {
                        VStack(spacing: 16) {
                            Text("🧩")
                                .font(.system(size: 48))
                            Text("Chưa có addon nào")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("Thêm addon từ link manifest.json\nđể mở rộng nguồn phim")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        Text("Đã cài đặt")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        ForEach(manager.addons) { addon in
                            AddonRow(
                                addon: addon,
                                onToggle: { manager.toggleAddon(id: addon.manifest.id) },
                                onDelete: {
                                    if let idx = manager.addons.firstIndex(where: { $0.id == addon.id }) {
                                        manager.removeAddon(at: IndexSet(integer: idx))
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            AddAddonSheet(
                addonURL: $addonURL,
                isLoading: $isLoading,
                errorMessage: $errorMessage,
                onAdd: { url, manifest in
                    manager.addAddon(url: url, manifest: manifest)
                    showAddSheet = false
                    addonURL = ""
                }
            )
        }
    }
}

struct AddonRow: View {
    let addon: SavedAddon
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo
            if let logo = addon.manifest.logo, let url = URL(string: logo) {
                CachedAsyncImage(url: url)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .overlay(Text("🧩").font(.system(size: 20)))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(addon.manifest.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("v\(addon.manifest.version)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { addon.enabled },
                set: { _ in onToggle() }
            ))
            .tint(.green)
            .scaleEffect(0.8)
            .frame(width: 44)
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 0.5))
    }
}

struct AddAddonSheet: View {
    @Binding var addonURL: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let onAdd: (String, AddonManifest) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Text("Thêm Addon")
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                
                Text("Dán link manifest.json của addon Stremio")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                TextField("https://.../manifest.json", text: $addonURL)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.4)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button {
                    Task {
                        isLoading = true
                        errorMessage = nil
                        do {
                            let manifest = try await AddonManager.shared.fetchManifest(from: addonURL)
                            await MainActor.run {
                                isLoading = false
                                onAdd(addonURL, manifest)
                            }
                        } catch {
                            await MainActor.run {
                                isLoading = false
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(isLoading ? "Đang kiểm tra..." : "Thêm Addon")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.6)))
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                }
                .disabled(addonURL.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}