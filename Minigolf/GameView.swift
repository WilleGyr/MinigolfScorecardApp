import SwiftUI

struct GameView: View {
    let playerNames: [String]
    let roundCount: Int
    let holeCount = 18

    @State private var scores: [[[Int?]]] // [player][hole][round]
    @State private var currentHole = 0
    @State private var currentPlayer = 0
    @State private var currentRound = 0
    @State private var showResults = false

    static let accentColors: [Color] = [.mint, .indigo, .orange, .pink, .purple, .teal]

    func accentColor(at i: Int) -> Color {
        Self.accentColors[i % Self.accentColors.count]
    }

    var activeColor: Color { accentColor(at: currentPlayer) }

    var chipWidth: CGFloat { roundCount <= 2 ? 56 : 44 }

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

    func scoreColor(_ s: Int) -> Color {
        switch s {
        case 1: return .mint
        case 2: return .blue
        default: return .orange
        }
    }

    func scoreBg(_ s: Int) -> Color {
        scoreColor(s).opacity(0.15)
    }

    func enterScore(_ s: Int) {
        scores[currentPlayer][currentHole][currentRound] = s
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            advance()
        }
    }

    func advance() {
        // Fill rounds for this player on this hole first, then next player, then next hole
        if currentRound < roundCount - 1 {
            currentRound += 1
        } else if currentPlayer < playerNames.count - 1 {
            currentPlayer += 1
            currentRound = 0
        } else if currentHole < holeCount - 1 {
            currentHole += 1
            currentPlayer = 0
            currentRound = 0
        } else {
            showResults = true
        }
    }

    func isHoleComplete(_ hole: Int) -> Bool {
        playerNames.indices.allSatisfy { p in
            (0..<roundCount).allSatisfy { r in scores[p][hole][r] != nil }
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Hole navigation
            HStack {
                Button {
                    if currentHole > 0 {
                        withAnimation(.spring(response: 0.3)) {
                            currentHole -= 1
                            currentPlayer = 0
                            currentRound = 0
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(currentHole > 0 ? Color.primary : Color.secondary.opacity(0.25))
                }
                .disabled(currentHole == 0)

                Spacer()

                VStack(spacing: 2) {
                    Text("Hål \(currentHole + 1)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("\(currentHole + 1) av \(holeCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    if currentHole < holeCount - 1 {
                        withAnimation(.spring(response: 0.3)) {
                            currentHole += 1
                            currentPlayer = 0
                            currentRound = 0
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(currentHole < holeCount - 1 ? Color.primary : Color.secondary.opacity(0.25))
                }
                .disabled(currentHole == holeCount - 1)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Progress dots
            HStack(spacing: 5) {
                ForEach(0..<holeCount, id: \.self) { h in
                    Capsule()
                        .fill(h == currentHole
                              ? activeColor
                              : (isHoleComplete(h) ? Color.mint.opacity(0.5) : Color.secondary.opacity(0.18)))
                        .frame(width: h == currentHole ? 18 : 6, height: 6)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                currentHole = h
                                currentPlayer = 0
                                currentRound = 0
                            }
                        }
                }
            }
            .padding(.vertical, 14)
            .animation(.spring(response: 0.3), value: currentHole)

            Divider()

            // Score table
            VStack(spacing: 0) {
                // Round header
                HStack(spacing: 0) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 16)

                    HStack(spacing: 8) {
                        ForEach(0..<roundCount, id: \.self) { r in
                            Text("R\(r + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: chipWidth)
                        }
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 28)

                ForEach(playerNames.indices, id: \.self) { p in
                    HStack(spacing: 0) {
                        // Avatar + name
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(accentColor(at: p).opacity(0.18))
                                    .frame(width: 34, height: 34)
                                Text(String(playerNames[p].prefix(1)).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(accentColor(at: p))
                            }
                            Text(playerNames[p])
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)

                        // Score chips
                        HStack(spacing: 8) {
                            ForEach(0..<roundCount, id: \.self) { r in
                                let score = scores[p][currentHole][r]
                                let isActive = p == currentPlayer && r == currentRound

                                Button {
                                    withAnimation(.spring(response: 0.2)) {
                                        currentPlayer = p
                                        currentRound = r
                                    }
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(isActive
                                                  ? accentColor(at: p).opacity(0.15)
                                                  : (score != nil
                                                     ? scoreBg(score!)
                                                     : Color(uiColor: .tertiarySystemBackground)))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 11)
                                                    .stroke(isActive ? accentColor(at: p) : Color.clear,
                                                            lineWidth: 1.5)
                                            )

                                        if let s = score {
                                            Text("\(s)")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundStyle(scoreColor(s))
                                        } else {
                                            Text(isActive ? "·" : "—")
                                                .font(.system(size: isActive ? 28 : 15, weight: .bold))
                                                .foregroundStyle(isActive
                                                                 ? accentColor(at: p)
                                                                 : Color.secondary.opacity(0.3))
                                        }
                                    }
                                    .frame(width: chipWidth, height: 50)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.vertical, 6)

                    if p < playerNames.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .padding(.vertical, 8)

            Spacer()

            // Who's entering
            HStack(spacing: 6) {
                Circle()
                    .fill(activeColor.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .overlay {
                        Text(String(playerNames[currentPlayer].prefix(1)).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(activeColor)
                    }
                Text("\(playerNames[currentPlayer]), Runda \(currentRound + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            // Score buttons 1 / 2 / 3
            HStack(spacing: 12) {
                ForEach([1, 2, 3], id: \.self) { n in
                    Button { enterScore(n) } label: {
                        Text("\(n)")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 82)
                            .background(
                                n == 1 ? Color.mint.opacity(0.15) :
                                n == 2 ? Color(uiColor: .secondarySystemBackground) :
                                Color.orange.opacity(0.15)
                            )
                            .foregroundStyle(
                                n == 1 ? Color.mint :
                                n == 2 ? Color.primary :
                                Color.orange
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("Minigolf")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Avsluta") { showResults = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.mint)
            }
        }
        .navigationDestination(isPresented: $showResults) {
            ResultsView(playerNames: playerNames, scores: scores, roundCount: roundCount)
        }
    }
}

#Preview {
    NavigationStack {
        GameView(playerNames: ["William", "Alfred", "David"], roundCount: 4)
    }
}
