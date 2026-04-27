//
//  EmptyAccountsView.swift
//  KamFinAssetTrack
//
//  Empty state shown on the Account list when the user has zero accounts.
//  Includes a primary CTA to open the create form.
//

import SwiftUI

/// Empty-state view for the Account list (AC-9 from Scope Package).
struct EmptyAccountsView: View {

    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "#C9A961").opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Add your first account")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Track your ISAs, pensions, property, crypto, cash and debts — all in one private place.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onAdd) {
                Label("Add Account", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#E4C77A"), Color(hex: "#C9A961")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: .rect(cornerRadius: 12)
                    )
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add your first account")
            .accessibilityHint("Opens a form to create a new account")
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A1628"))
    }
}

#Preview {
    EmptyAccountsView(onAdd: {})
}
