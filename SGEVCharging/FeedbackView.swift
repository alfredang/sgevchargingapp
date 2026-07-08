import SwiftUI

struct FeedbackView: View {
    private static let whatsAppNumber = "6588666375"

    @State private var title = ""
    @State private var message = ""
    @State private var showCannotOpenAlert = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case message
    }

    private var canSend: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("We'd love your feedback")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)

                        Text("Tell us what's working well or what we can improve. Your message opens in WhatsApp so you can send it to us directly.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.mutedInk)

                            TextField("e.g. Suggestion for the map", text: $title)
                                .textInputAutocapitalization(.sentences)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .title)
                                .onSubmit { focusedField = .message }
                                .padding(12)
                                .background(Theme.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.mutedInk)

                            TextField("Write your message here", text: $message, axis: .vertical)
                                .lineLimit(5...10)
                                .textInputAutocapitalization(.sentences)
                                .focused($focusedField, equals: .message)
                                .padding(12)
                                .background(Theme.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .appCard()

                    Button(action: sendViaWhatsApp) {
                        Label("Send via WhatsApp", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSend ? Theme.primary : Theme.mutedInk.opacity(0.4),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .disabled(!canSend)
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .alert("WhatsApp not available", isPresented: $showCannotOpenAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't open WhatsApp on this device. Please install WhatsApp or contact us at +65 8866 6375.")
            }
        }
    }

    private func sendViaWhatsApp() {
        focusedField = nil

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines: [String] = []
        if !trimmedTitle.isEmpty {
            lines.append(trimmedTitle)
        }
        if !trimmedMessage.isEmpty {
            lines.append(trimmedMessage)
        }

        let text = lines.joined(separator: "\n\n")
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: "https://wa.me/\(Self.whatsAppNumber)?text=\(encoded)") else {
            showCannotOpenAlert = true
            return
        }

        UIApplication.shared.open(url) { success in
            if !success {
                showCannotOpenAlert = true
            }
        }
    }
}

#Preview {
    FeedbackView()
}
