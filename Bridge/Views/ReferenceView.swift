import SwiftUI

/// The at-the-table glossary: search a term or browse by group. Free for
/// everyone and one tap from Home, because the moment it is needed is
/// mid-game with cards in hand, not during practice.
struct ReferenceView: View {
    @State private var query = ""

    private var groups: [(GlossaryGroup, [GlossaryTerm])] {
        GlossaryGroup.allCases.compactMap { group in
            let terms = ReferenceContent.terms(in: group, matching: query)
            return terms.isEmpty ? nil : (group, terms)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if groups.isEmpty {
                    emptyState
                } else {
                    ForEach(groups, id: \.0.id) { group, terms in
                        section(group, terms)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 28)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search terms")
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ group: GlossaryGroup, _ terms: [GlossaryTerm]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: group.icon)
                    .font(.caption)
                    .foregroundStyle(Theme.jade)
                    .accessibilityHidden(true)
                Text(group.title.uppercased())
                    .font(.caption.weight(.heavy))
                    .kerning(1.3)
                    .foregroundStyle(Theme.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 6)
            VStack(spacing: 0) {
                ForEach(Array(terms.enumerated()), id: \.element.id) { index, term in
                    termRow(term)
                    if index < terms.count - 1 {
                        Divider().background(Theme.rule).padding(.leading, 14)
                    }
                }
            }
            .themedCard(corner: 16)
        }
    }

    private func termRow(_ term: GlossaryTerm) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term.term)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(term.definition)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(Theme.jade.opacity(0.5))
                .accessibilityHidden(true)
            Text("No term matches “\(query)”")
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 16)
    }
}
