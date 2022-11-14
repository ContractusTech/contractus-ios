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

enum UploadFileContentState {
    case none, visible
}

fileprivate let ALLOW_FILE_TYPES: [UTType] = [.image, .data, .text, .pdf, .data, .plainText, .utf8PlainText, .zip, .bz2]

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

struct UploadFileView: View {
    enum SheetType: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case selectImage, camera, importFile
    }

    @StateObject var viewModel: AnyViewModel<UploadFileState, UploadFileInput>
    var action: (UploadFileResult?) -> Void

    @State private var position: UploadFilePosition = .hidden
    @State private var sheetType: SheetType? = nil
    @State private var selectingImage = false
    @State private var showBackground: Bool = true
    @State private var uploadFraction: Int?

    var body: some View {
        VStack(spacing: 24) {
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
                                    .resizable()
                                    .frame(width: 12, height: 12)
                            }
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 23)
                                    .stroke(R.color.buttonBackgroundPrimary.color, lineWidth: 1)
                            )

                        }
                        .offset(x: 12, y: -12)
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
                            selectingImage.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                VStack(spacing: 12){
                                    Image(systemName: "photo.on.rectangle.angled")

                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)

                                        .foregroundColor(R.color.secondaryText.color)
                                    Text(R.string.localizable.uploadFileButtonSelectGallery())
                                        .font(.footnote)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(R.color.secondaryBackground.color)
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
                                        .frame(width: 32, height: 32)

                                        .foregroundColor(R.color.secondaryText.color)
                                    Text(R.string.localizable.uploadFileButtonCamera())
                                        .font(.footnote)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(R.color.secondaryBackground.color)
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
                                    Text("File")
                                        .font(.footnote)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)


                        }

                    }

                }
            }
            if uploadFileButtonIsVisible {
                UploadingButtonView(state: viewModel.state.state) {
                    viewModel.trigger(.upload)
                }
            }

            if canCancel {
                Button {
                    position = .hidden
                    viewModel.trigger(.clear)
                    action(nil)
                } label: {
                    HStack {
                        Spacer()
                        Text(R.string.localizable.commonCancel())
                            .font(.body.weight(.bold))
                        Spacer()
                    }
                }
            }
        }
        .padding(.bottom, 16)
        .onDisappear {
            viewModel.trigger(.clear)
        }
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


    }

    var canCancel: Bool {
        switch viewModel.state.state {
        case .uploading, .encrypting:
            return false
        case .success, .error, .none, .selected:
            return true
        }
    }

    var fileIsVisible: Bool {
        switch viewModel.state.state {
        case .none:
            return false
        case .selected, .error, .success, .encrypting, .uploading:
            return true
        }
    }

    var uploadFileButtonIsVisible: Bool {
        switch viewModel.state.state {
        case .none:
            return false
        case .selected, .error, .success, .encrypting, .uploading:
            return true
        }
    }

    var clearButtonIsVisible: Bool {
        switch viewModel.state.state {
        case .none, .success, .encrypting, .uploading:
            return false
        case .selected, .error:
            return true
        }
    }

}

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
                VStack(alignment: .center) {
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
        }
        .padding(12)
        .background(R.color.fourthBackground.color)
        .cornerRadius(22)
    }


}

struct UploadingButtonView: View {

    let state: UploadFileState.State
    var action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Spacer()
                Text(titleButton)
                    .font(.body.weight(.bold))
                    .foregroundColor(R.color.buttonTextPrimary.color)
                Spacer()
            }
            .padding()
        }
        .background(R.color.buttonBackgroundPrimary.color)
        .cornerRadius(12)
        .disabled(isDisabled)
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
        }
    }

    private var titleButton: String {
        switch state {
        case .none, .selected:
            return R.string.localizable.uploadFileStateUploadFile()
        case .encrypting:
            return R.string.localizable.uploadFileStateEncrypting()
        case .uploading(let fraction):
            return R.string.localizable.uploadFileStateUploading(String(format: "%@%", fraction))
        case .error:
            return "Retry"
        case .success:
            return R.string.localizable.uploadFileStateSuccess()
        }
    }
}

struct UploadFileView_Previews: PreviewProvider {

    static var previews: some View {
        UploadFileView(viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(account: Mock.account, filesAPIService: nil))) { _ in

        }

        UploadFileItemView(file: Mock.file) {

        }
    }
}
