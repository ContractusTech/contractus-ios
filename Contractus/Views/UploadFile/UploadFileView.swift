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

    var body: some View {
        VStack(spacing: 24) {
            switch viewModel.state.state {
            case .encrypting:
                Text("Ecrypting...")
            case .uploading(let fraction):
                Text("Uploading: \(fraction) %")
            case .error:
                Text("Error")
            case .success(let file):
                Text("Success").onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [file] in
                        action(file)
                    }
                }

            case .none:
                VStack(spacing: 24) {
                    HStack {
                        Text("Select")
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
                                    Text("Gallery")
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
                                    Text("Camera")
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
                                    Image(systemName: "doc")
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
            case .selected(let name):
                VStack {
                    Button {
                        viewModel.trigger(.clear)
                    } label: {
                        Text("Clear")
                    }
                    Text(name)
                    Button {
                        viewModel.trigger(.upload)
                    } label: {
                        Text("Upload")
                    }
                }
            }

            switch viewModel.state.state {
            case .encrypting, .uploading:
                EmptyView()
            default:

                Button {
                    position = .hidden
                    action(nil)
                } label: {
                    HStack {
                        Spacer()
                        Text(R.string.localizable.commonCancel())
                        Spacer()
                    }
                }
                .background(R.color.secondaryBackground.color)
                .buttonStyle(SecondaryLargeButton())
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
                        viewModel.trigger(.selected(RawFile.asPNGImage(image, path: path)))
                    }
                case .selectImage:
                    ImagePickerView(sourceType: .photoLibrary) { image, path in
                        viewModel.trigger(.selected(RawFile.asPNGImage(image, path: path)))
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

}

struct UploadFileView_Previews: PreviewProvider {

    static var previews: some View {
        UploadFileView(viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(account: Mock.account, filesAPIService: nil))) { _ in

        }
    }
}
