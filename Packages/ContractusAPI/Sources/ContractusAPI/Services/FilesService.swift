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

    public func upload(data: UploadFile, progressCallback: @escaping (Double) -> Void, completion: @escaping (Swift.Result<UploadedFile, APIClientError>) -> Void) {

        let uploadingFile = self.client.session.upload(multipartFormData: { multipartData in
            multipartData.append(data.data, withName: "file", fileName: data.fileName, mimeType: data.mimeType)
            multipartData.append(data.md5.data(using: .utf8)!, withName: "md5")
        }, to: client.server.path(ServicePath.uploadFile.value), method: .post)

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

    public func cancel(by id: UUID) {
        self.uploadingRequests.first(where: { $0.id == id })?.cancel()
        self.uploadingRequests.removeAll { $0.id == id }
    }
}

