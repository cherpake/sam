//
//  samApp.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI
import Combine
#if os(iOS)
import BackgroundTasks
#endif

#if os(macOS)
class WindowObserver: NSObject {
    var frameObserver: NSKeyValueObservation?
    var stateObserver: NSKeyValueObservation?
    init(window: NSWindow) {
        super.init()
        frameObserver = window.observe(\.frame) { window, change in
            UserDefaults.standard.windowFrame = window.frame
        }
        stateObserver = window.observe(\.isVisible, changeHandler: { window, change in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if window.isVisible == false {
                    NSApp.setActivationPolicy(.accessory)
                } else {
                    NSApp.setActivationPolicy(.regular)
                }
            }
        })
    }
    deinit {
        frameObserver?.invalidate()
        stateObserver?.invalidate()
    }
}

struct WindowAccessor: NSViewRepresentable {
    @State var observer: WindowObserver?
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let view, let window = view.window else {
                return
            }
            if let windowFrame = UserDefaults.standard.windowFrame {
                window.setFrame(windowFrame, display: true)
            }
            observer = WindowObserver(window: window)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) { }
}
#endif

@main
struct samApp: App {
    
    @Environment(\.scenePhase) private var phase
    
    // Always put ObservableObject outside of the object that uses it!
    @State var viewModel = MainAppModel()
    
    @State var error: ErrorMessage? = nil
    @State var showError: Bool = false
    
    @State var cancallables = [AnyCancellable]()
    @State var totals: SpendRow? = nil
    
    @ViewBuilder
    func mainView() -> some View {
        MainAppView()
            .navigationTitle("SearchAds Manager")
            .environmentObject(viewModel)
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text("Code: \(error?.messageCode.rawValue ?? "") \(error?.message ?? "")")
            }
            .onAppear {
                SearchAds.instance.onError = { error in
                    self.error = error
                    self.showError = true
                }
                SearchAds.instance.onResponse = {
                    Blackbox.instance.increaseUserScore(1)
                }
                
                let _ = Blackbox.instance
                Blackbox.instance.increaseUserScore(1)
            }
    }
    
    var body: some Scene {
#if os(macOS)
        MenuBarExtra() {
            ExtraView()
                .environmentObject(viewModel)
        } label: {
            Image(systemName: "chart.bar.xaxis")
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let _ = UserDefaults.standard.clientId, let _ = UserDefaults.standard.clientSecret {
                            NSApp.setActivationPolicy(.accessory)
                        } else {
                            NSApp.setActivationPolicy(.regular)
                            NSWorkspace.shared.open(URL(string: "sam://main")!)
                        }
                    }
                    
                    viewModel.$todayReportUpdated
                        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                        .sink { report in
                            totals = viewModel.todayReport?.grandTotals?.total
                        }
                        .store(in: &cancallables)
                    
                    Task {
                        do {
                            try await viewModel.updateTodayReport()
                        } catch let error {
                            debugPrint(error)
                        }
                    }
                }
            if let totals {
                Text("\((Float(totals.localSpend.amount) ?? 0.0).formatted(.currency(code: totals.localSpend.currency)))")
            }
        }
        .menuBarExtraStyle(.window)
#endif
        
        #if os(macOS)
        Window("SearchAds Manager", id: "main") {
            mainView()
                .background(WindowAccessor())
        }
        .handlesExternalEvents(matching: ["sam://main"])
        .defaultSize({
            if let rect = UserDefaults.standard.windowFrame {
                return rect.size
            } else {
                return CGSize(width: 800, height: 600)
            }
        }())
        .defaultPosition({
            if let rect = UserDefaults.standard.windowFrame {
                return .init(x: rect.origin.x, y: rect.origin.y)
            } else {
                return .center
            }
        }())
        #else
        WindowGroup {
            mainView()
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            default: break
            }
        }
        .backgroundTask(.appRefresh("totals.refresh")) {
            Task {
                do {
                    try await viewModel.updateTodayReport()
                } catch {
                    
                }
            }
            DispatchQueue.main.async {
                scheduleAppRefresh()
            }
        }
        #endif
    }
}

#if os(iOS)
extension samApp {
    
    func scheduleAppRefresh() {
        debugPrint("Scheduling background fetch of totals")
        let request = BGAppRefreshTaskRequest(identifier: "totals.refresh")
        request.earliestBeginDate = .now.addingTimeInterval(15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    
}
#endif

#if os(macOS)
struct ExtraView: View {
    @EnvironmentObject var viewModel: MainAppModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if let totals = viewModel.todayReport?.grandTotals?.total {
                DetailsTotalsView(totals: totals)
                    .environmentObject(viewModel)
                    .padding()
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }
                        
            HStack {
                Button {
                    dismiss()
                    NSApp.setActivationPolicy(.regular)
                    NSWorkspace.shared.open(URL(string: "sam://main")!)
                } label: {
                    Text("Show")
                }
                Button {
                    viewModel.updateReports()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                }
            }
            .padding()
            .background(.black)
        }
    }
}
#endif
