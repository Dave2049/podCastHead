//
//import SwiftUI
//import Combine
//
//
//final class RemoteImage : ObservableObject {
//
//    enum LoadingState {
//
//        case initial
//
//        case inProgress
//
//        case success(_ image: Image)
//
//        case failure
//    }
//
//    @Published var loadingState: LoadingState = .initial
//
//    let url: URL
//
//    init(url: URL) {
//        self.url = url
//        debugPrint(url)
//    }
//
//    func load() {
//        loadingState = .inProgress
//
//        cancellable = URLSession(configuration: .default)
//            .dataTaskPublisher(for: url)
//            .map {
//                guard let value = UIImage(data: $0.data) else {
//                    return .failure
//                }
//
//                return .success(Image(uiImage: value))
//            }
//            .catch { _ in
//                Just(.failure)
//            }
//            .receive(on: RunLoop.main)
//            .assign(to: \.loadingState, on: self)
//    }
//
//    private var cancellable: AnyCancellable?
//}
//
//
//struct URLImage : View {
//
//    init(url: URL) {
//        remoteImage = RemoteImage(url: url)
//        remoteImage.load()
//    }
//
//    var body: some View {
//        ZStack {
//            switch remoteImage.loadingState {
//                case .initial:
//                    EmptyView()
//                case .inProgress:
//                    Text("Loading")
//                case .success(let image):
//                    image
//                case .failure:
//                    Text("Failed")
//            }
//        }
//    }
//
//    @ObservedObject private var remoteImage: RemoteImage
//}
