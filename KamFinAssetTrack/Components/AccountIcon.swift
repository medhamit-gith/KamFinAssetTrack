//
//  AccountIcon.swift
//  KamFinAssetTrack
//
//  Circular icon rendered with the AccountType's accent colour background
//  and its SF Symbol on top. Used in AccountRow and AccountDetail.
//

import SwiftUI

/// Circular badge that visually encodes an `AccountType`.
struct AccountIcon: View {

    let type: AccountType
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(type.accentColor.opacity(0.2))
            Circle()
                .strokeBorder(type.accentColor.opacity(0.4), lineWidth: 1)
            Image(systemName: type.iconName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(type.accentColor)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)   // decorative; row surfaces type in label
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(AccountType.allCases) { type in
            HStack(spacing: 12) {
                AccountIcon(type: type)
                Text(type.displayName)
                    .foregroundStyle(.white)
                Spacer()
            }
        }
    }
    .padding()
    .background(Color(hex: "#0A1628"))
}
