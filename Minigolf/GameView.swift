import SwiftUI

struct GameView: View {
    let playerNames: [String]
    let roundCount: Int
    let holeCount = 18

    @State private var scores: [[[Int?]]] // [player][hole][round]
    @State private var selectedPlayer = 0
    @State private var selectedRound = 0
    @State private var showResults = false

    static let accentColors: [Color] = [.mint, .indigo, .orange, .pink, .purple, .teal]

    func accentColor(at i: Int) -> Color {
        Self.accentColors[i % Self.accentColors.count]
    }

    var currentColor: Color { accentColor(at: selectedPlayer) }

    init(playerNames: [String], roundCount: Int) {
        self.playerNames = playerNames
        self.roundCount = roundCount
        _scores = State(initialValue:
            Array(repeating:
                Array(repeating:
                    Array(repeating: nil, count: roundCount),
                    count: 18),
                count: playerNames.count))
    }

    func roundTotal(player: Int, round: Int) -> Int {
        scores[player].compactMap { $0[round] }.reduce(0, +)
    }

    func holesPlayed(player: Int, round: Int) -> Int {
        scores[player].filter { $0[round] != nil }.count
    }

    func relativeScore(player: Int, round: Int) -> Int {
        roundTotal(player: player, round: round) - holesPlayed(player: player, round: round) * 2
    }

    func relativeLabel(_ r: Int) -> String {
        r == 0 ? "E" : (r > 0 ? "+\(r)" : "\(r)")
    }

    func relativeColor(_ r: Int) -> Color {
        r == 0 ? .secondary : (r > 0 ? .red : .mint)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Player selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(playerNames.indices, id: \.self) { i in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPlayer = i
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accentColor(at: i).opacity(0.22))
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        Text(String(playerNames[i].prefix(1)).uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(accentColor(at: i))
                                    }
                                Text(playerNames[i])
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selectedPlayer == i
                                        ? accentColor(at: i)
                                        : Color(uiColor: .secondarySystemBackground))
                            .foregroundStyle(selectedPlayer == i ? .black : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // Round selector
            if roundCount > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(0..<roundCount, id: \.self) { r in
                            Button {
                                withAnimation(.spring(response: 0.25)) { selectedRound = r }
                            } label: {
                                Text("Runda \(r + 1)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedRound == r
                                                ? currentColor.opacity(0.18)
                                                : Color.clear)
                                    .foregroundStyle(selectedRound == r ? currentColor : .secondary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            selectedRound == r ? currentColor.opacity(0.4) : Color.clear,
                                            lineWidth: 1))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Hole list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<holeCount, id: \.self) { hole in
                        HoleRow(
                            hole: hole,
                            score: $scores[selectedPlayer][hole][selectedRound],
                            accentColor: currentColor
                        )
                        if hole < holeCount - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            let total = roundTotal(player: selectedPlayer, round: selectedRound)
            let played = holesPlayed(player: selectedPlayer, round: selectedRound)
            let rel = relativeScore(player: selectedPlayer, round: selectedRound)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(playerNames[selectedPlayer])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text("\(total) slag")
                            .font(.headline.weight(.bold))
                        if played > 0 {
                            Text(relativeLabel(rel))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(relativeColor(rel))
                        }
                    }
                }
                Spacer()
                Button {
                    showResults = true
                } label: {
                    Text("Avsluta")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Color.red.opacity(0.85))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(playerNames[selectedPlayer])
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResults) {
            ResultsView(playerNames: playerNames, scores: scores, roundCount: roundCount)
        }
    }
}

struct HoleRow: View {
    let hole: Int
    @Binding var score: Int?
    let accentColor: Color

    var scoreColor: Color {
        guard let s = score else { return .clear }
        switch s {
        case 1: return .mint
        case 2: return .primary
        case 3: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(hole + 1)")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
                .padding(.leading, 20)

            Circle()
                .fill(score != nil ? scoreColor : Color.clear)
                .frame(width: 7, height: 7)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    guard let s = score else { return }
                    score = s > 1 ? s - 1 : nil
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(score == nil ? Color.gray.opacity(0.3) : Color.primary)

                Text(score.map { "\($0)" } ?? "—")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(score == nil ? Color.gray.opacity(0.3) : scoreColor)
                    .frame(width: 30)
                    .animation(nil, value: score)

                Button {
                    score = (score ?? 0) + 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(.primary)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 52)
        .background(score != nil ? accentColor.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        GameView(playerNames: ["William", "Alfred", "David"], roundCount: 2)
    }
}
