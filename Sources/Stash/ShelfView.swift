// Luminous Desktop native-product style: an illuminated graphite shelf with calm, nearby file actions.
import AppKit
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

struct ShelfView: View {
    @ObservedObject var manager: ShelfWindowManager
    @State private var items: [StashedItem] = []
    @State private var isTargeted = false
    @State private var previewURL: URL?
    @State private var isEditingTitle = false
    @State private var editableTitle = ""
    @State private var shareFeedback: String?
    @State private var autoClearWorkItem: DispatchWorkItem?
    @FocusState private var isTitleFocused: Bool
    @AppStorage("stash.defaultShareDestination") private var defaultShareDestination = ShareDestination.airDrop.rawValue
    @AppStorage("stash.autoClearEnabled") private var autoClearEnabled = true
    @AppStorage("stash.autoClearHours") private var autoClearHours = 24

    private var defaultDestination: ShareDestination {
        ShareDestination(rawValue: defaultShareDestination) ?? .airDrop
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            if items.isEmpty { emptyState } else { itemGrid }
        }
        .padding(12)
        .frame(width: 304, height: 326)
        .background(shelfMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isTargeted ? StashTheme.glow : Color.white.opacity(0.18), lineWidth: isTargeted ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.42), radius: 24, x: 0, y: 12)
        .quickLookPreview($previewURL)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: addDroppedFiles)
        .onDisappear { autoClearWorkItem?.cancel() }
    }

    private var header: some View {
        HStack(spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(StashTheme.glow)
                    .frame(width: 24, height: 24)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(StashTheme.glow.opacity(0.12)))

                if isEditingTitle {
                    TextField("Shelf name", text: $editableTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .focused($isTitleFocused)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.white.opacity(0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(StashTheme.glow.opacity(0.8), lineWidth: 1))
                        .onSubmit(commitTitle)
                        .onChange(of: isTitleFocused) { _, focused in if !focused { commitTitle() } }
                } else {
                    Button {
                        manager.makeKey()
                        editableTitle = manager.title
                        isEditingTitle = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { isTitleFocused = true }
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(manager.title).font(.system(size: 12, weight: .bold)).lineLimit(1)
                            Text(items.isEmpty ? "Ready for a drop" : "\(items.count) items nearby")
                                .font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Rename shelf")
                }
            }

            Spacer(minLength: 0)

            if !items.isEmpty {
                Menu {
                    Button { shareAll(to: defaultDestination) } label: {
                        Label("Share via \(defaultDestination.rawValue)", systemImage: defaultDestination.symbol)
                    }
                    Divider()
                    ForEach(ShareDestination.allCases) { option in
                        Button { shareAll(to: option) } label: { Label(option.rawValue, systemImage: option.symbol) }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(StashTheme.glow)
                        .frame(width: 27, height: 27)
                        .background(Circle().fill(StashTheme.glow.opacity(0.11)))
                }
                .menuStyle(.borderlessButton)
                .help("Share shelf — default: \(defaultDestination.rawValue)")
            }

            Button(action: clearOrHide) {
                Image(systemName: items.isEmpty ? "xmark" : "minus.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 27, height: 27)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help(items.isEmpty ? "Close shelf" : "Clear shelf")
        }
        .padding(.horizontal, 3)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            ZStack {
                Circle().fill(StashTheme.glow.opacity(0.08)).frame(width: 62, height: 62)
                Circle().stroke(StashTheme.glow.opacity(0.34), lineWidth: 1).frame(width: 62, height: 62)
                Image(systemName: "arrow.down.to.line.compact")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(StashTheme.glow)
            }
            Text("Drop files here").font(.system(size: 14, weight: .semibold))
            Text("Shake while dragging to summon Stash")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.025)))
    }

    private var itemGrid: some View {
        VStack(spacing: 7) {
            if let shareFeedback {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(StashTheme.glow)
                    Text(shareFeedback).lineLimit(1)
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76, maximum: 84), spacing: 9)], spacing: 9) {
                    ForEach(items) { item in
                        ItemCardView(
                            item: item,
                            onRemove: { remove(item) },
                            onPreview: { previewURL = item.url },
                            onCopyPath: { copyPath(item.url) }
                        )
                        .onDrag { NSItemProvider(item: item.url as NSSecureCoding, typeIdentifier: UTType.fileURL.identifier) }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shelfMaterial: some View {
        ZStack {
            Rectangle().fill(.regularMaterial)
            LinearGradient(colors: [Color.white.opacity(0.16), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [StashTheme.glow.opacity(0.12), .clear], center: .bottomTrailing, startRadius: 1, endRadius: 210)
        }
    }

    private func addDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url = (item as? URL) ?? (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                guard let url, let safeURL = StashFileGuard.usableLocalURL(url) else { return }
                DispatchQueue.main.async {
                    guard !items.contains(where: { $0.url == safeURL }) else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        items.append(StashedItem(url: safeURL))
                        manager.updateItemCount(items.count)
                        scheduleAutoClear()
                    }
                }
            }
            accepted = true
        }
        return accepted
    }

    private func clearOrHide() {
        if items.isEmpty { manager.close(); return }
        autoClearWorkItem?.cancel()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            items.removeAll()
            manager.updateItemCount(0)
            manager.hide()
        }
    }

    private func commitTitle() {
        guard isEditingTitle else { return }
        manager.updateTitle(editableTitle)
        isEditingTitle = false
    }

    private func remove(_ item: StashedItem) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            items.removeAll(where: { $0.id == item.id })
            manager.updateItemCount(items.count)
            if items.isEmpty { manager.hide() }
            scheduleAutoClear()
        }
    }

    private func copyPath(_ url: URL) {
        StashTheme.copyPath(url)
        withAnimation { shareFeedback = "File path copied" }
        dismissFeedback()
    }

    private func shareAll(to destination: ShareDestination) {
        let urls = items.compactMap { StashFileGuard.usableLocalURL($0.url) }
        guard !urls.isEmpty else {
            withAnimation { shareFeedback = "No readable local files are available to share" }
            dismissFeedback()
            return
        }
        let serviceName: NSSharingService.Name? = switch destination {
        case .airDrop: .sendViaAirDrop
        case .messages: .composeMessage
        case .mail: .composeEmail
        case .systemSheet: nil
        }

        if let serviceName, let service = NSSharingService(named: serviceName), service.canPerform(withItems: urls) {
            StashFileGuard.withScopedAccess(to: urls[0]) { service.perform(withItems: urls) }
        } else if let contentView = manager.panel?.contentView {
            NSSharingServicePicker(items: urls).show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }

        withAnimation { shareFeedback = "Preparing \(items.count) items for \(destination.rawValue)" }
        dismissFeedback()
    }

    private func dismissFeedback() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { withAnimation { shareFeedback = nil } }
    }

    private func scheduleAutoClear() {
        autoClearWorkItem?.cancel()
        guard autoClearEnabled, !items.isEmpty else { return }
        let workItem = DispatchWorkItem {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                items.removeAll()
                manager.updateItemCount(0)
                manager.hide()
            }
        }
        autoClearWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(autoClearHours * 3_600), execute: workItem)
    }
}

struct ItemCardView: View {
    @ObservedObject var item: StashedItem
    let onRemove: () -> Void
    let onPreview: () -> Void
    let onCopyPath: () -> Void
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Image(nsImage: item.thumbnail)
                    .renderingMode(.original)
                    .resizable().scaledToFit().frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(item.name).font(.system(size: 10, weight: .medium)).lineLimit(1).truncationMode(.middle)
                Text(item.fileSizeDescription).font(.system(size: 8)).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(width: 80, height: 87)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color.white.opacity(isHovered ? 0.105 : 0.045)))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color.white.opacity(isHovered ? 0.24 : 0.07), lineWidth: 1))

            if isHovered {
                HStack(spacing: 3) {
                    Button(action: onPreview) { Image(systemName: "eye").actionBadge() }.buttonStyle(.plain).help("Quick Look")
                    ShareLink(item: item.url) { Image(systemName: "square.and.arrow.up").actionBadge() }.buttonStyle(.plain).help("Share")
                    Button(action: onCopyPath) { Image(systemName: "doc.on.doc").actionBadge() }.buttonStyle(.plain).help("Copy file path")
                    Button(action: onRemove) { Image(systemName: "xmark").actionBadge() }.buttonStyle(.plain).help("Remove from shelf")
                }
                .offset(x: 3, y: -3)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onHover { hover in withAnimation(.easeOut(duration: 0.16)) { isHovered = hover } }
        .onTapGesture(count: 2, perform: onPreview)
        .contextMenu {
            Button("Quick Look", action: onPreview)
            ShareLink(item: item.url) { Label("Share", systemImage: "square.and.arrow.up") }
            Button("Copy File Path", action: onCopyPath)
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
            Divider()
            Button("Remove from Shelf", role: .destructive, action: onRemove)
        }
    }
}

private extension Image {
    func actionBadge() -> some View {
        self.font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(Color.black.opacity(0.78)))
    }
}
