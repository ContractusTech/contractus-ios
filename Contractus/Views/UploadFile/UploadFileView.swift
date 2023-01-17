//
//  UploadFileView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.08.2022.
//

import SwiftUI
import ContractusAPI
import UniformTypeIdentifiers.UTType
import ResizableSheet

enum UploadFilePosition: CGFloat, CaseIterable, Equatable, RawRepresentable {
    case top = 0.97,
         middle = 0.51,
         hidden = 0
}

fileprivate let ALLOW_FILE_TYPES: [UTType] = [.image, .data, .text, .pdf, .data, .plainText, .utf8PlainText, .zip, .bz2]

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

// MARK: - UploadFileView

struct UploadFileView: View {

    enum AlertType {
        case error(String), needConfirmForceUpdate
    }

    enum ActionResult {
        case close, success(DealMetadata, DealsService.ContentType)
    }

    enum SheetType: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case selectImage, camera, importFile
    }

    @StateObject var viewModel: AnyViewModel<UploadFileState, UploadFileInput>
    var action: (ActionResult) -> Void

    @State private var sheetType: SheetType? = nil
    @State private var uploadFraction: Int?
    @State private var alertType: AlertType?

    var body: some View {
        VStack(spacing: 12) {
            if fileIsVisible {
                ZStack (alignment: .topTrailing) {
                    UploadFileItemView(file: viewModel.state.selectedFile) {
                        viewModel.trigger(.clear)
                    }
                    if clearButtonIsVisible {
                        Button {
                            viewModel.trigger(.clear)
                        } label: {
                            HStack {
                                Constants.closeImage
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(R.color.buttonIconBase.color)

                            }
                            .padding(8)
                            .background(R.color.accentColor.color)
                            .cornerRadius(24)
                        }
                        .offset(x: -12, y: 12)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text(R.string.localizable.uploadFileButtonSelect())
                            .font(.title2.weight(.heavy))
                    }
                    HStack(spacing: 12) {
                        Button {
                            sheetType = .selectImage
                        } label: {
                            HStack {
                                Spacer()
                                VStack(spacing: 12){
                                    Image(systemName: "photo.on.rectangle.angled")

                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)

                                        .foregroundColor(R.color.secondaryText.color)
                                    Text(R.string.localizable.uploadFileButtonSelectGallery())
                                        .font(.footnote)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(R.color.fourthBackground.color)
                            .cornerRadius(20)
                        }

                        Button {
                            sheetType = .camera
                        } label: {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "camera")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)

                                        .foregroundColor(R.color.secondaryText.color)
                                    Text(R.string.localizable.uploadFileButtonCamera())
                                        .font(.footnote)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(R.color.fourthBackground.color)
                            .cornerRadius(20)
                        }

                        Button {
                            sheetType = .importFile
                        } label: {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.viewfinder")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 32)

                                        .foregroundColor(R.color.secondaryText.color)
                                    Text(R.string.localizable.uploadFileButtonFile())
                                        .font(.footnote)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(R.color.fourthBackground.color)
                            .cornerRadius(20)
                        }
                    }
                }
            }
            if uploadFileButtonIsVisible {
                UploadingButtonView(state: viewModel.state.state) {
                    viewModel.trigger(.uploadAndUpdate)
                }
            }

            if canCancel {
                Button {
                    viewModel.trigger(.clear)
                    action(.close)
                } label: {
                    HStack {
                        Spacer()
                        Text(R.string.localizable.commonCancel())
                            .font(.body.weight(.bold))
                        Spacer()
                    }
                }
                .padding()
            }
        }
        .padding(.bottom, 16)
        .padding(.top, 4)
        .onDisappear {
            viewModel.trigger(.clear)
        }
        .onChange(of: viewModel.state.state, perform: { newState in
            switch newState {
            case .success(let meta):
                action(.success(meta, viewModel.state.contentType))
            case .needConfirmForce:
                alertType = .needConfirmForceUpdate
            case .none, .error, .encrypting, .selected, .uploading, .saving:
                break
            }

        })
        .fullScreenCover(item: $sheetType, content: { type in
            switch type {
            case .camera:
                ImagePickerView(sourceType: .camera) { image, path in
                    if let rawFile = RawFile.fromImage(image, path: path) {
                        viewModel.trigger(.selected(rawFile))
                    }

                }
            case .selectImage:
                ImagePickerView(sourceType: .photoLibrary) { image, path in
                    if let rawFile = RawFile.fromImage(image, path: path) {
                        viewModel.trigger(.selected(rawFile))
                    }
                }
            case .importFile:
                DocumentPickerView(types: ALLOW_FILE_TYPES) { data, url in
                    let mimeType = MimeType(url: url)
                    let file = RawFile(data: data, name: url.lastPathComponent, mimeType: mimeType.value)
                    viewModel.trigger(.selected(file))
                }
            }
        })
        .alert(item: $alertType, content: { type in
            switch type {
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message))
            case .needConfirmForceUpdate:
                return Alert(
                    title: Text(R.string.localizable.commonAttention()),
                    message:  Text(R.string.localizable.dealTextEditorMessageForceUpdate()),
                    primaryButton: Alert.Button.destructive(Text(R.string.localizable.dealTextEditorForceUpdate())) {
                        viewModel.trigger(.updateForce)
                    },
                    secondaryButton: Alert.Button.cancel {
                        viewModel.trigger(.clear)
                    })
            }

        })


    }

    private var canCancel: Bool {
        switch viewModel.state.state {
        case .uploading, .encrypting, .success, .saving:
            return false
        case .error, .none, .selected, .needConfirmForce:
            return true
        }
    }

    private var fileIsVisible: Bool {
        switch viewModel.state.state {
        case .none:
            return false
        case .selected, .error, .success, .encrypting, .uploading, .saving, .needConfirmForce:
            return true
        }
    }

    private var uploadFileButtonIsVisible: Bool {
        switch viewModel.state.state {
        case .none:
            return false
        case .selected, .error, .success, .encrypting, .uploading, .saving, .needConfirmForce:
            return true
        }
    }

    private var clearButtonIsVisible: Bool {
        switch viewModel.state.state {
        case .none, .success, .encrypting, .uploading, .saving, .needConfirmForce:
            return false
        case .selected, .error:
            return true
        }
    }

}

// MARK: - UploadFileItemView

struct UploadFileItemView: View {

    let file: RawFile?
    var clearAction: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            if let file = file {
                if file.isImage, let image = UIImage(data: file.data) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(R.color.secondaryBackground.color)
                        .cornerRadius(6)
                }
                else {
                    // TODO: -
                }
                VStack(alignment: .center, spacing: 4) {
                    Text(file.name)
                        .font(.callout.weight(.medium))
                        .foregroundColor(R.color.textBase.color)
                    HStack(spacing: 12) {
                        Text(file.formattedSize)
                            .font(.callout.weight(.regular))
                            .foregroundColor(R.color.secondaryText.color)
                    }
                }
            } else {
                EmptyView()
            }
            if file?.isLargeForEncrypting ?? false {
                VStack {
                    Text(R.string.localizable.uploadFileLargeFile())
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(R.color.yellow.color)
                        .lineLimit(0)
                }

            }

        }
        .padding(16)
        .background(R.color.mainBackground.color)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(R.color.textFieldBorder.color, lineWidth: 1))
    }


}

// MARK: - UploadingButtonView

struct UploadingButtonView: View {

    let state: UploadFileState.State
    var action: () -> Void

    var body: some View {
        CButton(title: titleButton, style: .primary, size: .large, isLoading: false, isDisabled: isDisabled) {
            action()
        }
    }

    private var isDisabled: Bool {
        switch state {
        case .none, .selected:
            return false
        case .encrypting:
            return true
        case .uploading(_):
            return true
        case .error:
            return false
        case .success:
            return true
        case .saving:
            return true
        case .needConfirmForce:
            return true
        }
    }

    private var textColor: Color {
        switch state {
        case .none, .selected:
            return R.color.buttonTextPrimary.color
        case .encrypting:
            return R.color.secondaryText.color
        case .uploading(_), .saving, .needConfirmForce:
            return R.color.secondaryText.color
        case .error:
            return R.color.white.color
        case .success:
            return R.color.secondaryText.color
        }
    }

    private var buttonBackground: Color {
        if isDisabled {
            return R.color.fourthBackground.color
        }
        if case .error = state {
            return R.color.yellow.color
        }

        return R.color.buttonBackgroundPrimary.color
    }

    private var titleButton: String {
        switch state {
        case .none, .selected:
            return R.string.localizable.uploadFileStateUploadFile()
        case .encrypting:
            return R.string.localizable.uploadFileStateEncrypting()
        case .uploading(let fraction):
            return R.string.localizable.uploadFileStateUploading("\(fraction)%")
        case .error:
            return "Retry"
        case .saving, .needConfirmForce:
            return "Saving..."
        case .success:
            return "Saved"
        }
    }
}

extension UploadFileView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return "error"
        case .needConfirmForceUpdate:
            return "needConfirmForceUpdate"
        }
    }
}

struct UploadFileView_Previews: PreviewProvider {

    static var previews: some View {
        UploadFileView(viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(dealId: Mock.deal.id, content: Mock.deal.meta ?? .init(files: []), contentType: .metadata, secretKey: Mock.account.privateKey, dealService: nil, filesAPIService: nil))) { _  in

        }

        UploadFileItemView(file: Mock.file) {

        }
    }
}
