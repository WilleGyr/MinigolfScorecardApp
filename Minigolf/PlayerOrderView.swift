import SwiftUI

struct PlayerEntry: Identifiable {
    let id = UUID()
    var name: String
}

struct PlayerOrderView: View {
    @State private var players: [PlayerEntry] = [
        PlayerEntry(name: "William"),
        PlayerEntry(name: "Alfred"),
        PlayerEntry(name: "David")
    ]
    @State private var roundCount = 1
    @State private var showGame = false
    @FocusState private var focusedId: UUID?

    static let accentColors: [Color] = [.mint, .indigo, .orange, .pink, .purple, .teal]

    func accentColor(at i: Int) -> Color {
        Self.accentColors[i % Self.accentColors.count]
    }

    var validNames: [String] {
        players.enumerated().map { (i, p) in
            let t = p.name.trimmingCharacters(in: .whitespaces)
            return t.isEmpty ? "Spelare \(i + 1)" : t
        }
    }

    var canStart: Bool { players.count >= 2 }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minigolf")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                            Text("Ny omgång")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 36)

                        // Players section
                        sectionLabel("Spelare", icon: "person.2.fill")

                        VStack(spacing: 0) {
                            ForEach($players) { $player in
                                let index = players.firstIndex(where: { $0.id == player.id }) ?? 0
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(accentColor(at: index).opacity(0.18))
                                            .frame(width: 40, height: 40)
                                        Text(player.name.prefix(1).uppercased().isEmpty
                                             ? "?" : String(player.name.prefix(1).uppercased()))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(accentColor(at: index))
                                    }

                                    TextField("Namn", text: $player.name)
                                        .font(.body)
                                        .focused($focusedId, equals: player.id)

                                    if players.count > 2 {
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                players.removeAll { $0.id == player.id }
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red.opacity(0.7))
                                                .font(.system(size: 22))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)

                                if player.id != players.last?.id {
                                    Divider().padding(.leading, 68)
                                }
                            }

                            if players.count < 6 {
                                Button {
                                    let entry = PlayerEntry(name: "")
                                    withAnimation(.spring(response: 0.3)) {
                                        players.append(entry)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        focusedId = entry.id
                                    }
                                } label: {
                                    Label("Lägg till spelare", systemImage: "plus.circle.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.mint)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 28)

                        // Rounds section
                        sectionLabel("Rundor", icon: "arrow.clockwise")

                        HStack(spacing: 10) {
                            ForEach([1, 2, 3, 4], id: \.self) { n in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { roundCount = n }
                                } label: {
                                    VStack(spacing: 3) {
                                        Text("\(n)")
                                            .font(.system(size: 26, weight: .bold, design: .rounded))
                                        Text(n == 1 ? "runda" : "rundor")
                                            .font(.caption2.weight(.medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 66)
                                    .background(roundCount == n
                                                ? Color.mint
                                                : Color(uiColor: .secondarySystemBackground))
                                    .foregroundStyle(roundCount == n ? Color.black : Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                    .padding(.horizontal, 20)
                }

                // Floating start button
                VStack(spacing: 0) {
                    Button {
                        showGame = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("Starta")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(canStart ? .black : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canStart
                                    ? Color.mint
                                    : Color(uiColor: .tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canStart)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(
                    LinearGradient(
                        colors: [Color(uiColor: .systemBackground).opacity(0),
                                 Color(uiColor: .systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showGame) {
                GameView(playerNames: validNames, roundCount: roundCount)
            }
        }
    }

    @ViewBuilder
    func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.bottom, 8)
    }
}

#Preview {
    PlayerOrderView()
}
