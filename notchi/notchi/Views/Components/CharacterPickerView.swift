import SwiftUI

struct CharacterPickerView: View {
    @State private var selectedCharacter = AppSettings.selectedCharacter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsRowView(icon: "person.2", title: "Character") {
                EmptyView()
            }

            HStack(spacing: 10) {
                ForEach(CharacterTheme.allCases) { theme in
                    CharacterThumbnail(
                        theme: theme,
                        isSelected: selectedCharacter == theme
                    ) {
                        selectedCharacter = theme
                        AppSettings.selectedCharacter = theme
                        NotificationCenter.default.post(name: .characterThemeDidChange, object: nil)
                    }
                }
            }
            .padding(.leading, 28)
        }
    }
}

private struct CharacterThumbnail: View {
    let theme: CharacterTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                SpriteSheetView(
                    spriteSheet: theme.previewSprite,
                    frameCount: 6,
                    columns: 6,
                    fps: 3,
                    isAnimating: true
                )
                .frame(width: 40, height: 40)

                Text(theme.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(
                        isSelected ? TerminalColors.primaryText : TerminalColors.dimmedText
                    )
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? TerminalColors.green : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
