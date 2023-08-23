//
//  MimeType.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.08.2022.
//

import Foundation

let DEFAULT_MIME_TYPE = "application/octet-stream"

let mimeTypes: [String: (String, FileGroup)] = [
    "html": ("text/html", FileGroup.web),
    "htm": ("text/html", FileGroup.web),
    "shtml": ("text/html", FileGroup.web),
    "css": ("text/css", FileGroup.code),
    "xml": ("text/xml", FileGroup.code),
    "gif": ("image/gif", FileGroup.image),
    "jpeg": ("image/jpeg", FileGroup.image),
    "jpg": ("image/jpeg", FileGroup.image),
    "js": ("application/javascript", FileGroup.code),
    "atom": ("application/atom+xml", FileGroup.code),
    "rss": ("application/rss+xml", FileGroup.code),
    "mml": ("text/mathml", FileGroup.code),
    "txt": ("text/plain", FileGroup.text),
    "jad": ("text/vnd.sun.j2me.app-descriptor", FileGroup.text),
    "wml": ("text/vnd.wap.wml", FileGroup.text),
    "htc": ("text/x-component", FileGroup.text),
    "png": ("image/png", FileGroup.image),
    "tif": ("image/tiff", FileGroup.image),
    "tiff": ("image/tiff", FileGroup.image),
    "wbmp": ("image/vnd.wap.wbmp", FileGroup.image),
    "ico": ("image/x-icon", FileGroup.image),
    "jng": ("image/x-jng", FileGroup.image),
    "bmp": ("image/x-ms-bmp", FileGroup.image),
    "svg": ("image/svg+xml", FileGroup.image),
    "svgz": ("image/svg+xml", FileGroup.image),
    "webp": ("image/webp", FileGroup.image),
    "woff": ("application/font-woff", FileGroup.unknown),
    "jar": ("application/java-archive", FileGroup.archive),
    "war": ("application/java-archive", FileGroup.archive),
    "ear": ("application/java-archive", FileGroup.archive),
    "json": ("application/json", FileGroup.code),
    "hqx": ("application/mac-binhex40", FileGroup.unknown),
    "doc": ("application/msword", FileGroup.doc),
    "pdf": ("application/pdf", FileGroup.doc),
    "ps": ("application/postscript", FileGroup.code),
    "eps": ("application/postscript", FileGroup.code),
    "ai": ("application/postscript", FileGroup.image),
    "rtf": ("application/rtf", FileGroup.doc),
    "m3u8": ("application/vnd.apple.mpegurl", FileGroup.unknown),
    "xls": ("application/vnd.ms-excel", FileGroup.doc),
    "eot": ("application/vnd.ms-fontobject", FileGroup.doc),
    "ppt": ("application/vnd.ms-powerpoint", FileGroup.doc),
    "wmlc": ("application/vnd.wap.wmlc", FileGroup.unknown),
    "kml": ("application/vnd.google-earth.kml+xml", FileGroup.unknown),
    "kmz": ("application/vnd.google-earth.kmz", FileGroup.unknown),
    "7z": ("application/x-7z-compressed", FileGroup.archive),
    "cco": ("application/x-cocoa", FileGroup.unknown),
    "jardiff": ("application/x-java-archive-diff", FileGroup.archive),
    "jnlp": ("application/x-java-jnlp-file", FileGroup.unknown),
    "run": ("application/x-makeself", FileGroup.unknown),
    "pl": ("application/x-perl", FileGroup.code),
    "pm": ("application/x-perl", FileGroup.code),
    "prc": ("application/x-pilot", FileGroup.unknown),
    "pdb": ("application/x-pilot", FileGroup.unknown),
    "rar": ("application/x-rar-compressed", FileGroup.archive),
    "rpm": ("application/x-redhat-package-manager", FileGroup.archive),
    "sea": ("application/x-sea", FileGroup.unknown),
    "swf": ("application/x-shockwave-flash", FileGroup.unknown),
    "sit": ("application/x-stuffit", FileGroup.unknown),
    "tcl": ("application/x-tcl", FileGroup.unknown),
    "tk": ("application/x-tcl", FileGroup.unknown),
    "der": ("application/x-x509-ca-cert", FileGroup.unknown),
    "pem": ("application/x-x509-ca-cert", FileGroup.unknown),
    "crt": ("application/x-x509-ca-cert", FileGroup.unknown),
    "xpi": ("application/x-xpinstall", FileGroup.unknown),
    "xhtml": ("application/xhtml+xml", FileGroup.unknown),
    "xspf": ("application/xspf+xml", FileGroup.unknown),
    "zip": ("application/zip", FileGroup.archive),
    "bin": ("application/octet-stream", FileGroup.unknown),
    "exe": ("application/octet-stream", FileGroup.unknown),
    "dll": ("application/octet-stream", FileGroup.unknown),
    "deb": ("application/octet-stream", FileGroup.unknown),
    "dmg": ("application/octet-stream", FileGroup.unknown),
    "iso": ("application/octet-stream", FileGroup.unknown),
    "img": ("application/octet-stream", FileGroup.unknown),
    "msi": ("application/octet-stream", FileGroup.unknown),
    "msp": ("application/octet-stream", FileGroup.unknown),
    "msm": ("application/octet-stream", FileGroup.unknown),
    "docx": ("application/vnd.openxmlformats-officedocument.wordprocessingml.document", FileGroup.doc),
    "xlsx": ("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", FileGroup.doc),
    "pptx": ("application/vnd.openxmlformats-officedocument.presentationml.presentation", FileGroup.doc),
    "mid": ("audio/midi", FileGroup.audio),
    "midi": ("audio/midi", FileGroup.audio),
    "kar": ("audio/midi", FileGroup.audio),
    "mp3": ("audio/mpeg", FileGroup.audio),
    "ogg": ("audio/ogg", FileGroup.audio),
    "m4a": ("audio/x-m4a", FileGroup.audio),
    "ra": ("audio/x-realaudio", FileGroup.audio),
    "3gpp": ("video/3gpp", FileGroup.video),
    "3gp": ("video/3gpp", FileGroup.video),
    "ts": ("video/mp2t", FileGroup.video),
    "mp4": ("video/mp4", FileGroup.video),
    "mpeg": ("video/mpeg", FileGroup.video),
    "mpg": ("video/mpeg", FileGroup.video),
    "mov": ("video/quicktime", FileGroup.video),
    "webm": ("video/webm", FileGroup.video),
    "flv": ("video/x-flv", FileGroup.video),
    "m4v": ("video/x-m4v", FileGroup.video),
    "mng": ("video/x-mng", FileGroup.video),
    "asx": ("video/x-ms-asf", FileGroup.video),
    "asf": ("video/x-ms-asf", FileGroup.video),
    "wmv": ("video/x-ms-wmv", FileGroup.video),
    "avi": ("video/x-msvideo", FileGroup.video),
]

public struct MimeType {
    let ext: String?

    public var value: String {
        guard let ext = ext else {
            return DEFAULT_MIME_TYPE
        }
        return mimeTypes[ext.lowercased()]?.0 ?? DEFAULT_MIME_TYPE
    }

    public var fileGroup: FileGroup {
        guard let ext = ext else {
            return .unknown
        }
        return mimeTypes[ext.lowercased()]?.1 ?? .unknown
    }

    public init(path: String) {
        ext = NSString(string: path).pathExtension
    }

    public init(path: NSString) {
        ext = path.pathExtension
    }

    public init(url: URL) {
        ext = url.pathExtension
    }
}

public enum FileGroup {
    case doc
    case text
    case image
    case video
    case archive
    case audio
    case web
    case code
    case unknown
}
