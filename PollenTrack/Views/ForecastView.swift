import SwiftUI

struct ForecastView: View {
    @EnvironmentObject private var atmoService: AtmoService
    @EnvironmentObject private var locationService: LocationService

    private let dayLabels = ["Aujourd'hui", "Demain", "Après-demain"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if atmoService.isLoading {
                        ProgressView("Chargement…")
                            .padding(.top, 40)
                    } else if let error = atmoService.errorMessage {
                        Text(error)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                    } else if atmoService.pollenData.isEmpty {
                        Text("Aucune prévision disponible")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(atmoService.pollenData.enumerated()), id: \.offset) { index, data in
                            dayCard(data: data, dayLabel: dayLabels[safe: index] ?? "J+\(index)")
                        }

                        legendSection
                    }
                }
                .padding()
            }
            .navigationTitle("Prévisions J+3")
        }
    }

    // MARK: - Day card
    private func dayCard(data: PollenData, dayLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.headline)
                    Text(data.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                levelBadge(level: data.pollenLevel)
            }

            Divider()

            // Taxon bar chart
            ForEach(data.taxons) { taxon in
                taxonBar(taxon: taxon)
            }
        }
        .padding()
        .glassCard(cornerRadius: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(dayLabel) : \(data.pollenLevel.label)")
    }

    // MARK: - Level badge
    private func levelBadge(level: PollenLevel) -> some View {
        Text(level.label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(level.color.opacity(0.85))
            .background(.ultraThinMaterial)
            .foregroundStyle(level.textColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityLabel("Niveau global : \(level.label)")
    }

    // MARK: - Taxon bar
    private func taxonBar(taxon: TaxonData) -> some View {
        HStack(spacing: 10) {
            Text(taxon.icon)
                .font(.subheadline)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(taxon.name)
                .font(.caption)
                .frame(width: 80, alignment: .leading)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 12)

                    let fraction = CGFloat(taxon.code) / 6.0
                    Capsule()
                        .fill(taxon.level.color)
                        .frame(width: max(geo.size.width * fraction, taxon.code > 0 ? 12 : 0),
                               height: 12)
                        .animation(.easeInOut, value: taxon.code)
                }
            }
            .frame(height: 12)

            Text("\(taxon.code)")
                .font(.caption.bold())
                .frame(width: 18)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(taxon.name) : \(taxon.level.label)")
    }

    // MARK: - Legend
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Légende officielle")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(PollenLevel.allCases, id: \.rawValue) { level in
                HStack(spacing: 10) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 14, height: 14)
                        .accessibilityHidden(true)
                    Text("\(level.rawValue) — \(level.label)")
                        .font(.caption)
                }
                .accessibilityLabel("\(level.rawValue) : \(level.label)")
            }
        }
        .padding()
        .glassCard(cornerRadius: 20)
    }
}

// MARK: - Safe array subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ForecastView()
        .environmentObject(AtmoService())
        .environmentObject(LocationService())
}
