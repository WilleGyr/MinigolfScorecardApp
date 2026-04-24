import SwiftUI
import Charts

struct ResultsView: View {
    let playerNames: [String]
    let scores: [[[Int?]]] // [player][hole][round]
    let roundCount: Int

    @State private var expandedPlayer: Int? = nil

    static let accentColors: [Color] = [.mint, .indigo, .orange, .pink, .purple, .teal]

    func accentColor(at i: Int) -> Color {
        Self.accentColors[i % Self.accentColors.count]
    }

    func totalScore(player: Int) -> Int {
        scores[player].flatMap { $0 }.compactMap { $0 }.reduce(0, +)
    }

    var rankedIndices: [Int] {
        playerNames.indices.sorted { totalScore(player: $0) < totalScore(player: $1) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resultat")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    Text("Omgång avslutad")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                ForEach(Array(rankedIndices.enumerated()), id: \.element) { rank, playerIndex in
                    PlayerResultCard(
                        rank: rank + 1,
                        playerName: playerNames[playerIndex],
                        scores: scores[playerIndex],
                        roundCount: roundCount,
                        accentColor: accentColor(at: playerIndex),
                        isExpanded: expandedPlayer == playerIndex
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            expandedPlayer = expandedPlayer == playerIndex ? nil : playerIndex
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Resultat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlayerResultCard: View {
    let rank: Int
    let playerName: String
    let scores: [[Int?]] // [hole][round]
    let roundCount: Int
    let accentColor: Color
    let isExpanded: Bool
    let onTap: () -> Void

    func roundTotal(_ r: Int) -> Int {
        scores.compactMap { $0[r] }.reduce(0, +)
    }

    func holesPlayed(_ r: Int) -> Int {
        scores.filter { $0[r] != nil }.count
    }

    func relativeScore(_ r: Int) -> Int {
        roundTotal(r) - holesPlayed(r) * 2
    }

    var averageTotal: Double {
        let totals = (0..<roundCount).map { roundTotal($0) }
        guard !totals.isEmpty else { return 0 }
        return Double(totals.reduce(0, +)) / Double(totals.count)
    }

    var rankLabel: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Summary row
                HStack(spacing: 14) {
                    Text(rankLabel)
                        .font(.system(size: 24))
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerName)
                            .font(.headline.weight(.bold))
                        Text(String(format: "Snitt: %.1f", averageTotal))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 14) {
                        ForEach(0..<roundCount, id: \.self) { r in
                            let rel = relativeScore(r)
                            VStack(spacing: 2) {
                                Text("\(roundTotal(r))")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                Text(rel == 0 ? "E" : (rel > 0 ? "+\(rel)" : "\(rel)"))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(rel == 0 ? Color.secondary : (rel > 0 ? Color.red : Color.mint))
                            }
                        }
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)

                if isExpanded {
                    VStack(spacing: 20) {
                        Divider().padding(.horizontal, 16)

                        chartSection(title: "SLAG PER RUNDA") {
                            RoundBarChart(scores: scores, roundCount: roundCount, accentColor: accentColor)
                                .frame(height: 140)
                        }

                        chartSection(title: "SLAG-FÖRDELNING") {
                            DistributionBarChart(scores: scores, accentColor: accentColor)
                                .frame(height: 140)
                        }

                        chartSection(title: "SCORE ÖVER TID") {
                            DeltaLineChart(scores: scores, accentColor: accentColor)
                                .frame(height: 140)
                        }
                    }
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accentColor.opacity(isExpanded ? 0.45 : 0.12), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func chartSection<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, 16)
            content()
                .padding(.horizontal, 10)
        }
    }
}

struct RoundBarChart: View {
    let scores: [[Int?]]
    let roundCount: Int
    let accentColor: Color

    var body: some View {
        let data = (0..<roundCount).map { r in
            scores.compactMap { $0[r] }.reduce(0, +)
        }

        Chart {
            ForEach(data.indices, id: \.self) { i in
                BarMark(
                    x: .value("Runda", "R\(i + 1)"),
                    y: .value("Slag", data[i])
                )
                .foregroundStyle(accentColor.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(data[i])")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in AxisValueLabel().font(.caption) }
        }
    }
}

struct DistributionBarChart: View {
    let scores: [[Int?]]
    let accentColor: Color

    struct BarData: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: Color
    }

    var data: [BarData] {
        let flat = scores.flatMap { $0 }.compactMap { $0 }
        return [
            BarData(label: "1", count: flat.filter { $0 == 1 }.count, color: .mint),
            BarData(label: "2", count: flat.filter { $0 == 2 }.count, color: accentColor),
            BarData(label: "3+", count: flat.filter { $0 >= 3 }.count, color: .orange)
        ]
    }

    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Slag", item.label),
                    y: .value("Antal", item.count)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in AxisValueLabel().font(.caption) }
        }
    }
}

struct DeltaLineChart: View {
    let scores: [[Int?]]
    let accentColor: Color

    struct Point: Identifiable {
        let id: Int
        let delta: Double
    }

    var points: [Point] {
        var result: [Point] = []
        var total = 0
        var played = 0
        for (i, holeScores) in scores.enumerated() {
            guard let s = holeScores.compactMap({ $0 }).first else { continue }
            total += s
            played += 1
            result.append(Point(id: i + 1, delta: Double(total) - Double(played * 2)))
        }
        return result
    }

    var body: some View {
        Chart {
            ForEach(points) { pt in
                LineMark(
                    x: .value("Hål", pt.id),
                    y: .value("Delta", pt.delta)
                )
                .foregroundStyle(accentColor)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Hål", pt.id),
                    y: .value("Delta", pt.delta)
                )
                .foregroundStyle(accentColor.opacity(0.08))
                .interpolationMethod(.catmullRom)
            }

            RuleMark(y: .value("Par", 0))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Color.secondary.opacity(0.4))
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel().font(.caption)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 3)) { _ in
                AxisValueLabel().font(.caption)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResultsView(
            playerNames: ["William", "Alfred", "David"],
            scores: Array(repeating:
                Array(repeating: [Int?](repeating: 2, count: 2), count: 18),
                count: 3),
            roundCount: 2
        )
    }
}
