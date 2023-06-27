---
title: "Navigation path"
categories: SwiftUI
---

# Intro

iOS 16
https://developer.apple.com/documentation/swiftui/navigationpath

# Navigation component

```
enum Route: Hashable {
    case main
    case detail(String)
    case otherDetail
}

extension Route {
    @ViewBuilder
    var view: some View {
        switch self {
        case .main:
            MainView()
        case .detail(let text):
            DetailView(text: text)
        case .otherDetail:
            OtherDetailView()
        }
    }
}
```

```
class NavigationModel: ObservableObject {
    @Published var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }
}
```

```
struct NavigationWrapper: View {
    @StateObject var navigationModel = NavigationModel()
    let root: any View

    init(@ViewBuilder rootView: () -> some View) {
        root = rootView()
    }

    var body: some View {
        NavigationStack(path: $navigationModel.path) {
            AnyView(root)
                .environmentObject(navigationModel)
                .navigationDestination(for: Route.self, destination: { route in
                    route
                        .view
                        .environmentObject(navigationModel)
                })
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

# Usage

```
struct ContentView: View {
    var body: some View {
        NavigationWrapper {
            MainView()
        }
    }
}
```



```
struct MainView: View {
    @EnvironmentObject var navigationModel: NavigationModel

    var buttons: some View {
        VStack(spacing: 20) {
            Button("Detail A") { navigationModel.push(.detail("A")) }
            Button("Detail B") { navigationModel.push(.detail("B")) }
            Button("Other detail") { navigationModel.push(.otherDetail) }
        }
    }

    var body: some View {
        Color.white
            .ignoresSafeArea()
            .overlay {
                buttons
            }
            .navigationTitle("Main")
    }
}
```



```
struct DetailView: View {
    let text: String

    var body: some View {
        Color.yellow
            .ignoresSafeArea()
            .overlay {
                Text("Value: \(text)")
            }
            .navigationTitle("Detail")
    }
}

struct OtherDetailView: View {
    var body: some View {
        Color.green
            .ignoresSafeArea()
            .overlay {
                Text("Other detail")
            }
    }
}
```

# Summary
All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/technical/app_secrets).