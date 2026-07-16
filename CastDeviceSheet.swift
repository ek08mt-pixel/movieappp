import SwiftUI
import AVKit

// MARK: - Cast Device Model
struct CastDevice: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let type: CastDeviceType
    var isConnected: Bool = false
    var signalStrength: Int = 3
}

enum CastDeviceType: String {
    case airplay = "AirPlay"
    case chromecast = "Chromecast"
    case webReceiver = "Web Receiver"
    case smartTV = "Smart TV"
}

// MARK: - Cast Mode
enum CastMode: String, CaseIterable {
    case remote = "Remote Mode"
    case dualScreen = "Dual Screen"
}

// MARK: - Cast Device Sheet
struct CastDeviceSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var devices: [CastDevice] = []
    @State private var selectedDevice: CastDevice?
    @State private var selectedMode: CastMode = .remote
    @State private var isScanning = true
    @State private var showModePicker = false
    
    // Dummy devices for demo
    let dummyDevices: [CastDevice] = [
        CastDevice(name: "Apple TV - Phòng khách", icon: "appletv.fill", type: .airplay, signalStrength: 4),
        CastDevice(name: "Samsung Smart TV", icon: "tv.fill", type: .smartTV, signalStrength: 3),
        CastDevice(name: "Chromecast - Phòng ngủ", icon: "rectangle.connected.to.line.below", type: .chromecast, signalStrength: 4),
        CastDevice(name: "MacBook Pro", icon: "laptopcomputer", type: .webReceiver, signalStrength: 3),
        CastDevice(name: "Máy chiếu LG", icon: "rectangle.fill.badge.person.crop", type: .smartTV, signalStrength: 2),
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                
                // Header
                HStack {
                    Text("Phát đến thiết bị")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if isScanning {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Button {
                        scanDevices()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Device List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(devices) { device in
                            deviceCard(device)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .frame(maxHeight: 280)
                
                // Cast Mode Selection
                if selectedDevice != nil {
                    VStack(spacing: 10) {
                        Divider()
                            .background(Color.white.opacity(0.15))
                            .padding(.horizontal, 20)
                        
                        Text("Chế độ")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            ForEach(CastMode.allCases, id: \.self) { mode in
                                modeButton(mode)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Cast Button
                        Button {
                            startCasting()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 14))
                                Text("Bắt đầu phát")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
                
                Spacer().frame(height: 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial.opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 30, y: -10)
        }
        .onAppear {
            scanDevices()
        }
    }
    
    // MARK: - Device Card
    func deviceCard(_ device: CastDevice) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedDevice?.id == device.id {
                    selectedDevice = nil
                } else {
                    selectedDevice = device
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(selectedDevice?.id == device.id ? 0.15 : 0.08))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: device.icon)
                        .font(.system(size: 18))
                        .foregroundColor(selectedDevice?.id == device.id ? .white : .white.opacity(0.7))
                }
                .overlay(
                    Circle()
                        .stroke(
                            selectedDevice?.id == device.id ? Color.blue.opacity(0.6) : .white.opacity(0.08),
                            lineWidth: selectedDevice?.id == device.id ? 2 : 1
                        )
                )
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(device.type.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        
                        // Signal dots
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .fill(i < device.signalStrength ? Color.green.opacity(0.7) : .white.opacity(0.15))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Checkmark
                if selectedDevice?.id == device.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedDevice?.id == device.id ? .white.opacity(0.08) : .white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                selectedDevice?.id == device.id ? Color.blue.opacity(0.3) : .white.opacity(0.05),
                                lineWidth: 0.5
                            )
                    )
            )
        }
    }
    
    // MARK: - Mode Button
    func modeButton(_ mode: CastMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMode = mode
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode == .remote ? "iphone.gen1" : "rectangle.split.2x1")
                    .font(.system(size: 20))
                Text(mode.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedMode == mode ? Color.blue.opacity(0.3) : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedMode == mode ? Color.blue.opacity(0.4) : .white.opacity(0.08),
                                lineWidth: 0.5
                            )
                    )
            )
        }
    }
    
    // MARK: - Actions
    func scanDevices() {
        isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            devices = dummyDevices
            isScanning = false
        }
    }
    
    func startCasting() {
        guard let device = selectedDevice else { return }
        // TODO: Start actual casting via AirPlay / Google Cast / WebRTC
        dismiss()
    }
}