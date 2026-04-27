//
//  AccountFormView.swift
//  KamFinAssetTrack
//
//  Sheet-presented form for creating or editing an Account.
//  Implements AC-2, AC-3, AC-7, AC-8 from the Scope Package.
//

import SwiftUI
import SwiftData

struct AccountFormView: View {

    // MARK: Config

    let mode: AccountFormMode
    let account: Account?

    // MARK: Environment

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: State

    @State private var vm: AccountFormViewModel
    @State private var showTypeChangeWarning = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showCustomProviderInput = false
    @State private var customProviderText = ""

    // @SceneStorage persists the draft across app backgrounding (AC-8).
    @SceneStorage("kfat.accountform.draft") private var draftJSON: String = ""

    // MARK: Init

    init(mode: AccountFormMode, account: Account? = nil) {
        self.mode = mode
        self.account = account
        _vm = State(initialValue: AccountFormViewModel(mode: mode, account: account))
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $vm.name, prompt: Text("e.g. HL Stocks & Shares ISA"))
                        .textContentType(.name)

                    Picker("Type", selection: $vm.type) {
                        ForEach(AccountType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Picker("Currency", selection: $vm.currency) {
                        ForEach(Currency.allCases.sorted(by: { $0.displayOrder < $1.displayOrder })) { c in
                            Text("\(c.symbol) \(c.displayName)").tag(c)
                        }
                    }
                }

                Section("Provider") {
                    providerPicker
                }

                Section("Notes") {
                    TextField("Optional notes", text: $vm.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if case .edit(let id) = mode {
                    Section {
                        Text("ID: \(id.uuidString.prefix(8))…")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Metadata")
                    }
                }
            }
            .navigationTitle(titleForMode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .fontWeight(.semibold)
                        .disabled(!vm.isValid)
                }
            }
            .confirmationDialog(
                "Change account type?",
                isPresented: $showTypeChangeWarning,
                titleVisibility: .visible
            ) {
                Button("Change Type", role: .destructive) {
                    performSave()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This account has holdings. Changing its type may affect how they display and aggregate. You can always change it back.")
            }
            .alert("Can't save", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showCustomProviderInput) {
                customProviderSheet
            }
            .onAppear {
                loadDraftIfNeeded()
            }
            .onChange(of: vm.name)     { _, _ in saveDraft() }
            .onChange(of: vm.provider) { _, _ in saveDraft() }
            .onChange(of: vm.type)     { _, _ in saveDraft() }
            .onChange(of: vm.currency) { _, _ in saveDraft() }
            .onChange(of: vm.notes)    { _, _ in saveDraft() }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var providerPicker: some View {
        let options = ProviderCatalog.matching(type: vm.type)

        Picker("Provider", selection: providerBinding(options: options)) {
            ForEach(options) { option in
                Text(option.name).tag(option.name)
            }
            // Always surface the current custom value if it isn't in the seed list.
            if !options.contains(where: { $0.name == vm.provider }) {
                Text(vm.provider).tag(vm.provider)
            }
        }
        .pickerStyle(.navigationLink)

        Button {
            customProviderText = ""
            showCustomProviderInput = true
        } label: {
            Label("Enter custom provider", systemImage: "pencil.circle")
        }
    }

    /// Binding that redirects taps on "Custom" to the custom-entry sheet
    /// rather than persisting the literal word "Custom" as the provider.
    private func providerBinding(options: [Provider]) -> Binding<String> {
        Binding(
            get: { vm.provider },
            set: { newValue in
                if let match = options.first(where: { $0.name == newValue }), match.isCustom {
                    customProviderText = ""
                    showCustomProviderInput = true
                } else {
                    vm.provider = newValue
                }
            }
        )
    }

    private var customProviderSheet: some View {
        NavigationStack {
            Form {
                TextField("Custom provider name", text: $customProviderText)
                if let dup = ProviderCatalog.hasSeededMatch(for: customProviderText) {
                    Text("This matches a seeded provider: \(dup.name). Consider selecting it from the list instead.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Custom Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustomProviderInput = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use") {
                        let trimmed = customProviderText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            vm.provider = trimmed
                        }
                        showCustomProviderInput = false
                    }
                    .disabled(customProviderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private var titleForMode: String {
        switch mode {
        case .create: return "New Account"
        case .edit:   return "Edit Account"
        }
    }

    private func attemptSave() {
        if let error = vm.validate() {
            validationMessage = message(for: error)
            showValidationAlert = true
            return
        }
        if vm.shouldWarnOnTypeChange() {
            showTypeChangeWarning = true
            return
        }
        performSave()
    }

    private func performSave() {
        do {
            _ = try vm.save(into: context)
            clearDraft()
            dismiss()
        } catch let error as AccountFormValidation {
            validationMessage = message(for: error)
            showValidationAlert = true
        } catch {
            validationMessage = "Couldn't save: \(error.localizedDescription)"
            showValidationAlert = true
        }
    }

    private func message(for error: AccountFormValidation) -> String {
        switch error {
        case .nameEmpty:     return "Name is required."
        case .nameTooLong:   return "Name must be 200 characters or fewer."
        case .providerEmpty: return "Provider is required."
        }
    }

    // MARK: - Draft persistence (@SceneStorage)

    private func saveDraft() {
        guard case .create = mode else { return }   // Only create-mode drafts persist.
        let draft = vm.snapshot()
        if let data = try? JSONEncoder().encode(draft),
           let str = String(data: data, encoding: .utf8)
        {
            draftJSON = str
        }
    }

    private func loadDraftIfNeeded() {
        guard case .create = mode else { return }
        guard !draftJSON.isEmpty,
              let data = draftJSON.data(using: .utf8),
              let draft = try? JSONDecoder().decode(AccountFormDraft.self, from: data)
        else { return }
        vm.applyDraft(draft)
    }

    private func clearDraft() {
        draftJSON = ""
    }
}

#Preview("Create") {
    let schema = Schema([Account.self, Holding.self, Snapshot.self, PriceQuote.self])
    let config = ModelConfiguration("Preview", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)

    return AccountFormView(mode: .create)
        .modelContainer(container)
}
