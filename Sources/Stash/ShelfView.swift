import SwiftUI
import UniformTypeIdentifiers

struct ShelfView: View {
    let manager: ShelfWindowManager
    @State private var items: [StashedItem] = []
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.accentColor)
                    Text("Stash")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !items.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            items.removeAll()
                            manager.hide()
                        }
                    }) {
                        Text("Clear")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
                
                Button(action: {
                    manager.hide()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            
            // Content Drop Area
            if items.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.04))
                            .frame(width: 54, height: 54)
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Text("Drop Files Here")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("Shake cursor anytime to stash")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64, maximum: 72)), GridItem(.adaptive(minimum: 64, maximum: 72))], spacing: 12) {
                        ForEach(items) { item in
                            ItemCardView(item: item, onRemove: {
                                removeItem(item)
                            })
                            .onDrag {
                                NSItemProvider(item: item.url as NSSecureCoding, typeIdentifier: UTType.fileURL.identifier)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 240, height: 260)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isTargeted
                    ? Color.accentColor
                    : Color.white.opacity(0.25),
                    lineWidth: isTargeted ? 2.5 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            var loaded = false
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                        var targetURL: URL?
                        if let data = item as? Data {
                            targetURL = URL(dataRepresentation: data, relativeTo: nil)
                        } else if let url = item as? URL {
                            targetURL = url
                        }
                        
                        if let url = targetURL {
                            DispatchQueue.main.async {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    if !self.items.contains(where: { $0.url == url }) {
                                        self.items.append(StashedItem(url: url))
                                    }
                                }
                            }
                        }
                    }
                    loaded = true
                }
            }
            return loaded
        }
    }
    
    private func removeItem(_ item: StashedItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items.removeAll(where: { $0.id == item.id })
            if items.isEmpty {
                manager.hide()
            }
        }
    }
}

struct ItemCardView: View {
    let item: StashedItem
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Image(nsImage: item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                Text(item.name)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
            }
            .frame(width: 68, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(isHovered ? 0.2 : 0.05), lineWidth: 1)
            )
            
            // Hover remove badge
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .background(Circle().fill(Color.white))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
