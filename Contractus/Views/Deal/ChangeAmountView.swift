import SwiftUI
import ContractusAPI
import Combine

extension Currency: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
    static let infoImage = Image(systemName: "info.circle.fill")
    static let listImage = Image(systemName: "list.bullet")
}

struct ChangeAmountView: View {

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>
    @State private var amountString: String = ""
    @State private var showInfo: Bool = false
    @State private var showSelectToken: Bool = false
    @State var holderMode: Bool = false
    @FocusState var isInputActive: Bool

    let amountPublisher = PassthroughSubject<String, Never>()
    private var didChange: (Amount, AmountValueType, Bool) -> Void

    init(
        viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>,
        didChange: @escaping (Amount, AmountValueType, Bool) -> Void
    ) {
        self._amountString = State(initialValue: viewModel.state.amount.formatted())
        if viewModel.tier == .holder {
            self._holderMode = .init(initialValue: viewModel.deal.allowHolderMode ?? false || viewModel.amount.token.holderMode)
        }

        self._viewModel = StateObject(wrappedValue: viewModel)
        self.didChange = didChange
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            TextField(R.string.localizable.changeAmountAmount(), text: $amountString)
                                .textFieldStyle(LargeTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .onAppear {
                                    isInputActive = true
                                }
                            Divider().frame(height: 30)
                            Button{
                                showSelectToken = true
                            } label: {
                                HStack {
                                    Text(viewModel.state.amount.token.code)
                                        .font(.body.weight(.regular))
                                        .foregroundColor(R.color.secondaryText.color)
                                    Constants.listImage
                                }
                                .padding(.horizontal, 16)
                            }
                            .disabled(viewModel.amountType == .checker)
                        }
                        .background(R.color.textFieldBackground.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 0.5)
                                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                        )
                        Group {
                            switch viewModel.amountType {
                            case .deal:
                                
                                VStack(spacing: 16) {
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(R.string.localizable.changeAmountHolderMode())
                                                    .font(.body)
                                                    .foregroundColor(R.color.textBase.color)
                                                    .multilineTextAlignment(.leading)
                                                Button {
                                                    showInfo = true
                                                } label: {
                                                    Constants.infoImage
                                                        .resizable()
                                                        .frame(width: 16, height: 16)
                                                        .aspectRatio(contentMode: .fit)
                                                        .foregroundColor(R.color.secondaryText.color)
                                                }
                                            }
                                            
                                            
                                            Text(R.string.localizable.changeAmountHolderModeHint())
                                                .font(.footnote)
                                                .foregroundColor(R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                        
                                        Toggle(isOn: $holderMode) {}
                                            .disabled(viewModel.state.tier == .basic || viewModel.state.amount.token.holderMode)
                                    }
                                    
                                    BorderDivider(
                                        color: R.color.textFieldBorder.color,
                                        width: 1
                                    )
                                    .padding(.horizontal, -12)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(R.string.localizable.changeAmountFeeTitle())
                                                    .font(.body)
                                                    .foregroundColor(R.color.textBase.color)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Spacer()
                                            if holderMode {
                                                Label(text: R.string.localizable.changeAmountFeeFree(), type: .primary)
                                            } else {
                                                if viewModel.state.feePercent == 0 && viewModel.state.state != .loading {
                                                    if viewModel.state.noAmount {
                                                        Text("➖")
                                                            .font(.body)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(R.color.secondaryText.color)
                                                            .multilineTextAlignment(.leading)
                                                    } else {
                                                        Label(text: R.string.localizable.changeAmountFeeFree(), type: .primary)
                                                    }
                                                } else {
                                                    if !viewModel.state.feeFormatted.isEmpty  {
                                                        Text(viewModel.state.feeFormatted)
                                                            .font(.body)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(R.color.textBase.color)
                                                            .multilineTextAlignment(.leading)
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(R.color.thirdBackground.color)
                                                            .frame(width: 42, height: 19)
                                                    }
                                                }
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            if !viewModel.state.fiatFeeFormatted.isEmpty {
                                                Text("\(R.string.localizable.changeAmountEstimateFiat()) ≈ \(viewModel.state.fiatFeeFormatted)")
                                                    .font(.footnote.weight(.semibold))
                                                    .foregroundColor(R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Text(R.string.localizable.changeAmountFeeCalculateDescription())
                                                .font(.footnote)
                                                .foregroundColor(R.color.labelTextAttention.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .padding(.all, 12)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .inset(by: 0.5)
                                        .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                                )
                                
                                if viewModel.state.hasChecker && (viewModel.state.checkerIsYou || viewModel.state.clientIsYou) {
                                    HStack {
                                        VStack {
                                            Text(R.string.localizable.changeAmountVerificationAmount())
                                                .font(.body)
                                                .foregroundColor(viewModel.state.amountType == .checker ? R.color.textBase.color : R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        if viewModel.state.state != .loading  {
                                            if !(viewModel.state.deal.checkerAmount?.isZero ?? true) {
                                                Text(viewModel.state.checkerAmount.formatted(withCode: true))
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(viewModel.state.amountType == .checker ? R.color.textBase.color : R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            } else {
                                                Text(R.string.localizable.commonNotSpecified())
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(viewModel.state.amountType == .checker ? R.color.textBase.color : R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(R.color.thirdBackground.color)
                                                .frame(width: 42, height: 19)
                                        }
                                    }
                                    Divider()
                                }
                                HStack {
                                    VStack {
                                        Text(R.string.localizable.changeAmountTotalAmount())
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    if viewModel.state.state != .loading  {
                                        Text(viewModel.state.totalAmount.formatted(withCode: true))
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(R.color.thirdBackground.color)
                                            .frame(width: 42, height: 19)
                                    }
                                }
                            case .checker:
                                VStack(spacing: 16) {
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(R.string.localizable.changeAmountDealAmount())
                                                .font(.body)
                                                .foregroundColor(R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(viewModel.state.dealAmount.formatted(withCode: true))
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(R.color.secondaryText.color)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    BorderDivider(
                                        color: R.color.textFieldBorder.color,
                                        width: 1
                                    )
                                    .padding(.horizontal, -12)
                                    
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(R.string.localizable.changeAmountHolderMode())
                                                .font(.body)
                                                .foregroundColor(R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        if holderMode {
                                            Label(text: R.string.localizable.commonOn(), type: .primary)
                                        } else {
                                            Label(text: R.string.localizable.commonOff(), type: .default)
                                        }
                                    }
                                    
                                    BorderDivider(
                                        color: R.color.textFieldBorder.color,
                                        width: 1
                                    )
                                    .padding(.horizontal, -12)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(R.string.localizable.changeAmountFeeTitle())
                                                    .font(.body)
                                                    .foregroundColor(R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                            Spacer()
                                            if viewModel.state.feePercent == 0 && viewModel.state.state != .loading {
                                                if viewModel.state.noAmount {
                                                    Text("➖")
                                                        .font(.body)
                                                        .foregroundColor(R.color.secondaryText.color)
                                                        .multilineTextAlignment(.leading)
                                                } else {
                                                    Label(text: R.string.localizable.changeAmountFeeFree(), type: .primary)
                                                }
                                            } else {
                                                if !viewModel.state.feeFormatted.isEmpty  {
                                                    Text(viewModel.state.feeFormatted)
                                                        .font(.body)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(R.color.secondaryText.color)
                                                        .multilineTextAlignment(.leading)
                                                } else {
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(R.color.thirdBackground.color)
                                                        .frame(width: 42, height: 19)
                                                }
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            if !viewModel.state.fiatFeeFormatted.isEmpty {
                                                Text("\(R.string.localizable.changeAmountEstimateFiat()) \(viewModel.state.fiatFeeFormatted)")
                                                    .font(.footnote.weight(.semibold))
                                                    .foregroundColor(R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                            Text(R.string.localizable.changeAmountFeeCalculateDescription())
                                                .font(.footnote)
                                                .foregroundColor(R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .inset(by: 0.5)
                                        .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                                )
                                
                                HStack {
                                    VStack {
                                        Text(R.string.localizable.changeAmountTotalAmount())
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    if viewModel.state.state != .loading  {
                                        Text(viewModel.state.totalAmount.formatted(withCode: true))
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(R.color.thirdBackground.color)
                                            .frame(width: 42, height: 19)
                                    }
                                }
                            case .ownerBond, .contractorBond:
                                Text(bondText)
                                    .font(.footnote)
                                    .foregroundColor(R.color.secondaryText.color)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.isInputActive = false
                    }
                }
                .onAppear() {
                    UIScrollView.appearance().keyboardDismissMode = .onDrag
                }
                VStack(spacing: 24) {
                    Text(R.string.localizable.changeAmountFeeDescription())
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                        .multilineTextAlignment(.leading)

                    CButton(
                        title: R.string.localizable.commonChange(),
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.state.state == .changingAmount,
                        isDisabled: (!viewModel.state.isValid || viewModel.state.state == .loading)
                    ) {
                        EventService.shared.send(event: DefaultAnalyticsEvent.dealChangeAmountUpdateTap)
                        viewModel.trigger(.update)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
            }
            .onChange(of: amountString, perform: { newAmount in
                amountPublisher.send(newAmount)
            })
            .onChange(of: viewModel.state.state, perform: { newValue in
                if newValue == .success {
                    didChange(viewModel.amount, viewModel.state.amountType, viewModel.allowHolderMode)
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .onReceive(amountPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main), perform: { amountText in
                viewModel.trigger(.changeAmount(amountText))
            })
            .onChange(of: holderMode, perform: { newValue in
                viewModel.trigger(.changeholderMode(newValue))
            })
            .sheet(isPresented: $showInfo) {
                NavigationView {
                    WebView(url: AppConfig.holderModeURL)
                        .edgesIgnoringSafeArea(.bottom)
                        .navigationBarItems(
                            trailing: Button(R.string.localizable.commonClose(), action: {
                                showInfo = false
                            })
                        )
                        .navigationTitle(R.string.localizable.commonInfo())
                        .navigationBarTitleDisplayMode(.inline)
                }
                .baseBackground()
            }
            .sheet(isPresented: $showSelectToken) {
                selectTokenView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)
                    }
                }
//                ToolbarItemGroup(placement: .keyboard) {
//                    Spacer()
//                    Button(R.string.localizable.commonDone()) {
//                        isInputActive = false
//                    }.font(.body.weight(.medium))
//                }
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .baseBackground()
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    var title: String {
        switch viewModel.state.amountType {
        case .deal:
            return R.string.localizable.changeAmountTitle()
        case .checker:
            return R.string.localizable.changeAmountVerificationAmount()
        case .contractorBond:
            if viewModel.contractorIsClient {
                if viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondClientYou()
                }
                return R.string.localizable.changeAmountBondClient()
            } else {
                if !viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondExecutorYou()
                }
                return R.string.localizable.changeAmountBondExecutor()
            }
        case .ownerBond:
            if viewModel.ownerIsClient {
                if viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondClientYou()
                }
                return R.string.localizable.changeAmountBondClient()
            } else {
                if !viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondExecutorYou()
                }
                return R.string.localizable.changeAmountBondExecutor()
            }
        }
    }
    
    var bondText: String {
        switch viewModel.state.amountType {
        case .deal:
            return ""
        case .checker:
            return ""
        case .contractorBond:
            if viewModel.contractorIsClient {
                if viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            } else {
                if !viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            }
        case .ownerBond:
            if viewModel.ownerIsClient {
                if viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            } else {
                if !viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            }
        }
    }

    @ViewBuilder
    func selectTokenView() -> some View {
        TokenSelectView(viewModel: .init(TokenSelectViewModel(
            allowHolderMode: false,
            mode: .single,
            tier: viewModel.state.tier,
            selectedTokens: [viewModel.state.amount.token],
            disableUnselectTokens: [],
            resourcesAPIService: try? APIServiceFactory.shared.makeResourcesService()))) { result in
                switch result {
                case .many, .none:
                    break
                case .single(let token):
                    viewModel.trigger(.changeToken(token))
                    holderMode = token.holderMode
                    showSelectToken.toggle()
                }
            }
    }
}

struct ChangeAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeAmountView(
            viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(ChangeAmountViewModel(
                deal: Mock.deal, account: Mock.account, amountType: .checker, dealService: nil, tier: .basic))) { _, _, _  in

                }
    }
}
