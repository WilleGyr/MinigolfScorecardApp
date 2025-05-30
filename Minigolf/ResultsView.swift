import SwiftUI
import Charts
import UIKit

struct ResultsView: View {
    let playerNames: [String]
    let scores: [[[String]]] // [player][hole][round]
    let roundCount: Int

    @State private var expandedPlayer: Int? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Resultat")
                    .font(.largeTitle)
                    .bold()
                ForEach(playerNames.indices, id: \.self) { playerIndex in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if expandedPlayer == playerIndex {
                                expandedPlayer = nil
                            } else {
                                expandedPlayer = playerIndex
                            }
                        }
                    }) {
                        PlayerResultCard(
                            playerName: playerNames[playerIndex],
                            scores: scores[playerIndex],
                            roundCount: roundCount,
                            isExpanded: expandedPlayer == playerIndex
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }

    func generateCSV() -> String {
        var lines: [String] = ["Spelare,Hål,Runda,Poäng"]
        for (playerIndex, player) in playerNames.enumerated() {
            for (holeIndex, hole) in scores[playerIndex].enumerated() {
                for (roundIndex, score) in hole.enumerated() {
                    lines.append("\(player),\(holeIndex + 1),\(roundIndex + 1),\(score)")
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}

struct PlayerResultCard: View {
    let playerName: String
    let scores: [[String]] // [hole][round]
    let roundCount: Int
    let isExpanded: Bool

    var averageTotal: Double {
        let totals = (0..<roundCount).map { roundIndex in
            scores.compactMap {
                $0.indices.contains(roundIndex) ? Int($0[roundIndex]) : nil
            }.reduce(0, +)
        }
        return totals.isEmpty ? 0 : Double(totals.reduce(0, +)) / Double(totals.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                Text(playerName)
                    .font(.title2)
                    .bold()

                Text("Snitt: \(String(format: "%.1f", averageTotal))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    ForEach(0..<roundCount, id: \.self) { roundIndex in
                        let total = scores.compactMap {
                            $0.indices.contains(roundIndex) ? Int($0[roundIndex]) : nil
                        }.reduce(0, +)
                        let relative = total - 36

                        VStack {
                            Text("\(total)")
                            Text(relative == 0 ? "(0)" : (relative > 0 ? "+\(relative)" : "\(relative)"))
                                .foregroundColor(relative == 0 ? .white : (relative > 0 ? .red : .green))
                                .font(.subheadline)
                        }
                    }
                }
            }

            if isExpanded {
                VStack(spacing: 12) {
                    ScorePerRoundChart(scores: scores)
                        .frame(height: 150)

                    ScoreDistributionChart(scores: scores)
                        .frame(height: 150)

                    DeltaOverTimeChart(scores: scores)
                        .frame(height: 150)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(backgroundColor(for: playerName))
        .cornerRadius(16)
        .shadow(radius: 4)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }

    private func backgroundColor(for name: String) -> Color {
        switch name.uppercased() {
        case "W": return Color.blue.opacity(0.3)
        case "A": return Color.green.opacity(0.3)
        case "D": return Color.red.opacity(0.3)
        default: return Color.gray.opacity(0.2)
        }
    }
}

struct ScorePerRoundChart: View {
    let scores: [[String]] // [hole][round]

    var body: some View {
        let roundCount = scores.first?.count ?? 0
        let data = (0..<roundCount).map { roundIndex in
            scores.compactMap { Int($0[roundIndex]) }.reduce(0, +)
        }

        Chart {
            ForEach(data.indices, id: \.self) { i in
                BarMark(
                    x: .value("Runda", "Runda \(i+1)"),
                    y: .value("Poäng", data[i])
                )
                .annotation(position: .top) {
                    Text("\(data[i])")
                        .font(.caption)
                }
            }
        }
    }
}

struct ScoreDistributionChart: View {
    let scores: [[String]] // [hole][round]

    var body: some View {
        let flat = scores.flatMap { $0 }
        let counts: [String: Int] = ["1", "2", "3"].reduce(into: [:]) { dict, key in
            dict[key] = flat.filter { $0 == key }.count
        }

        Chart {
            ForEach(["1", "2", "3"], id: \.self) { score in
                BarMark(
                    x: .value("Poäng", score),
                    y: .value("Antal", counts[score] ?? 0)
                )
                .annotation(position: .top) {
                    Text("\(counts[score] ?? 0)")
                        .font(.caption)
                }
            }
        }
    }
}

struct DeltaOverTimeChart: View {
    let scores: [[String]] // [hole][round]
    var deltas: [Double] {
        var values: [Double] = []
        var strokesSoFar = 0
        var holesPlayed = 0
        for holeScores in scores {
            let score = holeScores.compactMap { Int($0) }.first ?? 0
            holesPlayed += 1
            strokesSoFar += score
            let delta = Double(strokesSoFar) - Double(holesPlayed * 2)
            values.append(delta)
        }
        return values
    }

    var body: some View {
        Chart {
            ForEach(deltas.indices, id: \.self) { i in
                LineMark(
                    x: .value("Hål", i + 1),
                    y: .value("Delta", deltas[i])
                )
            }
        }
    }
}

#Preview {
    GameView(
        playerNames: ["W", "A"],
        roundCount: 1
    )
}
