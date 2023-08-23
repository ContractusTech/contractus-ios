//
//  FilesService.swift
//  
//
//  Created by Simon Hudishkin on 04.08.2022.
//

import Foundation
import Alamofire

public final class FilesService: BaseService {

    private var uploadingRequests: [UploadRequest] = []
    private var downloadingRequests: [DownloadRequest] = []

    public func upload(data: UploadFile, progressCallback: @escaping (Double) -> Void, completion: @escaping (Swift.Result<UploadedFile, APIClientError>) -> Void) {

        let uploadingFile = self.client.session.upload(multipartFormData: { multipartData in
            multipartData.append(data.data, withName: "file", fileName: data.fileName, mimeType: data.mimeType)
            multipartData.append(data.md5.data(using: .utf8)!, withName: "md5")
        }, to: client.server.path(ServicePath.uploadFile.value), method: .post, headers: client.appHeaders)

        uploadingRequests.append(uploadingFile)
        uploadingFile
            .uploadProgress(closure: { progress in
                progressCallback(progress.fractionCompleted)
            })
            .validate()
            .responseDecodable(of: UploadedFile.self) {[weak self, uploadingFile] response in
                guard let self = self else { return }
                self.uploadingRequests.removeAll { $0.id == uploadingFile.id }
                completion(self.process(response: response))
            }
    }

    public func cancelUpload(by id: UUID) {
        self.uploadingRequests.first(where: { $0.id == id })?.cancel()
        self.uploadingRequests.removeAll { $0.id == id }
    }

    public func cancelDownload(by id: UUID) {
        self.downloadingRequests.first(where: { $0.id == id })?.cancel()
        self.downloadingRequests.removeAll { $0.id == id }
    }

    public func getLocalDocumentURL(_ serverURL: URL) -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(serverURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }

    public func download(url: URL, progressCallback: @escaping (Double) -> Void, completion: @escaping (Swift.Result<URL, APIClientError>) -> Void) -> UUID {

//        if let documentURL = getLocalDocumentURL(url) {
//            completion(.success(documentURL))
//            return
//        }

        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(url.lastPathComponent).appendingPathComponent(url.lastPathComponent)
            debugPrint(fileURL.absoluteString)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let downloadRequest = self.client.session.download(url, to: destination)

        downloadingRequests.append(downloadRequest)

        downloadRequest.downloadProgress(closure: { progress in
            debugPrint(progress.fractionCompleted)
            progressCallback(progress.fractionCompleted)
        })
        .response(completionHandler: {[weak self, downloadRequest] response in
            guard let self = self else { return }
            self.downloadingRequests.removeAll { $0.id == downloadRequest.id }

            switch response.result {
            case .failure(let error):
                debugPrint(error.localizedDescription)
                completion(.failure(APIClientError.commonError(error)))
            case .success(let url):
                if let url = url {
                    completion(.success(url))
                } else {
                    completion(.failure(APIClientError.unknownError))
                }

            }
        })

        return downloadRequest.id
    }
}

