//
//  ImageLoader.swift
//  PodCastHead
//
//  Created by David Schnurr on 24.01.21.
//

import Foundation
import Combine

import SwiftUI
class ImageLoader: ObservableObject {
//    @Published var image: Image?
//
//    private(set) var isLoading = false
//
//    private let url: URL
//    private var cache: ImageCache?
//    private var cancellable: AnyCancellable?
//
//    private static let imageProcessingQueue = DispatchQueue(label: "image-processing")
//
//    init(url: URL, cache: ImageCache? = nil) {
//        self.url = url
//        self.cache = cache
//    }
//
//    deinit {
//        cancel()
//    }
//
//    func load() {
//        guard !isLoading else { return }
//
//        if let image = cache?[url] {
//            self.image = image
//            return
//        }
//
//        cancellable = URLSession.shared.dataTaskPublisher(for: url)
//            .map { Image(uiImage: UIImage) }
//            .replaceError(with: nil)
//            .handleEvents(receiveSubscription: { [weak self] _ in self?.onStart() },
//                          receiveOutput: { [weak self] in self?.cache($0) },
//                          receiveCompletion: { [weak self] _ in self?.onFinish() },
//                          receiveCancel: { [weak self] in self?.onFinish() })
//            .subscribe(on: Self.imageProcessingQueue)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] in self?.image = $0 }
//    }
//
//    func cancel() {
//        cancellable?.cancel()
//    }
//
//    private func onStart() {
//        isLoading = true
//    }
//
//    private func onFinish() {
//        isLoading = false
//    }
//
//    private func cache(_ image: Image?) {
//        image.map { cache?[url] = $0 }
//    }
}
