import SwiftUI

struct LanguageTabSelector: View {
    
    let languages: [String]
    @Binding var selectedLanguage: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Layout.tabSpacing) {
                ForEach(languages, id: \.self) { langCode in
                    LanguageTab(
                        code: langCode,
                        isSelected: selectedLanguage == langCode
                    ) {
                        withAnimation(.easeInOut(duration: AppConstants.Animation.tabSwitch)) {
                            selectedLanguage = langCode
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: AppConstants.Layout.tabHeight)
    }
}

struct LanguageTab: View {
    
    let code: String
    let isSelected: Bool
    let action: () -> Void
    
    private var languageColor: Color {
        AppConstants.LanguageStyle.color(for: code)
    }
    
    private var languageName: String {
        AppConstants.LanguageStyle.name(for: code)
    }
    
    var body: some View {
        Button(action: action) {
            Text(languageName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : languageColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? languageColor : languageColor.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(languageColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }
}

#Preview {
    @Previewable @State var selected: String? = "en"
    
    VStack(spacing: 20) {
        LanguageTabSelector(
            languages: ["en", "zh", "ja", "ko", "es", "fr", "de"],
            selectedLanguage: $selected
        )
        
        Text("Selected: \(selected ?? "none")")
    }
    .padding()
    .frame(width: 450)
}
