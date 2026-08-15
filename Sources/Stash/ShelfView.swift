import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct ShelfView: View {
    @ObservedObject var manager: ShelfWindowManager
    @State private var items: [StashedItem] = []
    @State private var isTargeted = false
    @State private var previewUrl: URL?
    @State private var isEditingTitle = false
    @State private var editableTitle = ""
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Header Bar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    if isEditingTitle {
                        TextField("Shelf Name", text: $editableTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .focused($isTitleFocused)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.primary.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.accentColor.opacity(0.8), lineWidth: 1)
                            )
                            .frame(maxWidth: 120)
                            .onSubmit {
                                commitTitle()
                            }
                            .onChange(of: isTitleFocused) { _, focused in
                                if !focused {
                                    commitTitle()
                                }
                            }
                    } else {
                        HStack(spacing: 4) {
                            Text(manager.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .onTapGesture {
                            manager.makeKey()
                            editableTitle = manager.title
                            isEditingTitle = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isTitleFocused = true
                            }
                        }
                        .help("Click to rename shelf")
                    }
                }
                
                Spacer()
                
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            items.removeAll()
                            manager.updateItemCount(0)
                            manager.close()
                        }
                    }) {
                        Text("Clear")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: {
                    if items.isEmpty {
                        manager.close()
                    } else {
                        manager.hide()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
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
                            .fill(Color.accentColor.opacity(0.08))
                            .frame(width: 54, height: 54)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("Drop Files Here")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))
                    
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
                            }, onPreview: {
                                previewUrl = item.url
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
                // Pure translucent material
                Rectangle()
                    .fill(.regularMaterial)
                
                // Translucent top highlight
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
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
        .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 8)
        .quickLookPreview($previewUrl)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            var loaded = false
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil as [AnyHashable: Any]?) { (item, error) in
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
                                        let newItem = StashedItem(url: url)
                                        self.items.append(newItem)
                                        self.manager.updateItemCount(self.items.count)
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
    
    private func commitTitle() {
        guard isEditingTitle else { return }
        manager.updateTitle(editableTitle)
        isEditingTitle = false
    }
    
    private func removeItem(_ item: StashedItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items.removeAll(where: { $0.id == item.id })
            manager.updateItemCount(items.count)
            if items.isEmpty {
                manager.close()
            }
        }
    }
}

struct ItemCardView: View {
    @ObservedObject var item: StashedItem
    let onRemove: () -> Void
    let onPreview: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Image(nsImage: item.thumbnail)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                Text(item.name)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary.opacity(0.9))
            }
            .frame(width: 68, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(isHovered ? 0.25 : 0.08), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            
            // Hover action badges
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onPreview) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.75))
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.75))
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .offset(x: 2, y: -2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            onPreview()
        }
    }
}
