import SwiftUI
import AppKit
import os

struct ResizableView: View {
    @ObservedObject var settings: WindowSettings

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: settings.cornerRadius)
                .fill(settings.color)
                .opacity(settings.opacity)
            ResizableNSViewRepresentable(settings: settings)
        }
        .frame(width: settings.width, height: settings.height)
        .background(Color.clear)
    }
}

struct ResizableNSViewRepresentable: NSViewRepresentable {
    @ObservedObject var settings: WindowSettings
    
    func makeNSView(context: Context) -> ResizableNSView {
        
        
        return ResizableNSView(settings: settings)
    }
    
    func updateNSView(_ nsView: ResizableNSView, context: Context) {
        nsView.settings = settings
    }
}

class ResizableNSView: NSView {
    var settings: WindowSettings
    var isResizing = false
    var isDragging = false
    var initialMouseLocation: NSPoint?
    var initialFrame: NSRect?
    var resizeEdge: ResizeEdge = .none
    let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ResizableNSView", category: "ResizableNSView")

    enum ResizeEdge {
        case none, left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight
    }

    init(settings: WindowSettings) {
        self.settings = settings
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited, .mouseMoved]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = self.convert(event.locationInWindow, from: nil)
        initialFrame = window?.frame

        isResizing = resizeEdge != .none
        isDragging = !isResizing

        os_log("Mouse Down - isResizing: %{public}@, isDragging: %{public}@, resizeEdge: %{public}@",
               log: logger,
               type: .debug,
               String(describing: self.isResizing),
               String(describing: self.isDragging),
               String(describing: self.resizeEdge))
        // 获取鼠标在屏幕上的当前位置
        let currentMouseLocation = NSEvent.mouseLocation
        
        os_log("Downing - pointer info: currentMouseLocation:(%{public}f, %{public}f) ",
               log: logger,
               type: .debug,
               
               currentMouseLocation.x,
               currentMouseLocation.y)
    }

    override func mouseDragged(with event: NSEvent) {
//        guard let window = self.window,
//              let initialMouseLocation = NSEvent.mouseLocation,
//              let initialFrame = initialFrame else { return }
//
//        let currentMouseLocation = NSEvent.mouseLocation
//        
//
        guard let window = self.window else { return }

       

        if isDragging {
            
            let currentMouseLocation = NSEvent.mouseLocation

            // 初始化初始鼠标位置和窗口框架为可选类型
            var initialMouseLocation: NSPoint?
            var initialFrame: NSRect?

            if initialMouseLocation == nil {
                // 记录初始鼠标位置和窗口框架
                initialMouseLocation = currentMouseLocation
                initialFrame = window.frame
            }

            // 使用条件绑定来解包可选类型的值
            guard let initialMouseLocation = initialMouseLocation,
                  let initialFrame = initialFrame else {
                // 如果初始鼠标位置或窗口框架为 nil，直接返回
                return
            }
                // 计算鼠标移动的距离
                let deltaX = currentMouseLocation.x - initialMouseLocation.x
                let deltaY = currentMouseLocation.y - initialMouseLocation.y
            
            // 计算新的窗口位置
            var newOrigin = NSPoint(
                x: initialFrame.origin.x + deltaX,
                y: initialFrame.origin.y + deltaY
            )

            // 获取当前屏幕的可见区域
            let screenFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

            // 确保窗口不会移出屏幕
            newOrigin.x = max(screenFrame.minX, min(newOrigin.x, screenFrame.maxX - window.frame.width))
            newOrigin.y = max(screenFrame.minY, min(newOrigin.y, screenFrame.maxY - window.frame.height))

            // 使用核心动画来平滑移动窗口
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.0  // 设置为0以获得即时响应，但保持平滑
                context.timingFunction = CAMediaTimingFunction(name: .linear)
                window.animator().setFrameOrigin(newOrigin)
            }, completionHandler: nil)


        } else if isResizing {
            let currentMouseLocation = NSEvent.mouseLocation
            let windowMouseLocation = window.convertPoint(fromScreen: currentMouseLocation)

            if initialMouseLocation == nil {
                initialMouseLocation = windowMouseLocation
                initialFrame = window.frame
            }

            guard let initialMouseLocation = initialMouseLocation,
                  let initialFrame = initialFrame else { return }

            let deltaX = windowMouseLocation.x - initialMouseLocation.x
            let deltaY = windowMouseLocation.y - initialMouseLocation.y
            var newFrame = window.frame
            switch resizeEdge {
            case .right, .bottomRight:
                newFrame.size.width = max(initialFrame.width + deltaX, 100)
                if resizeEdge == .bottomRight {
                    newFrame.size.height = max(initialFrame.height - deltaY, 100)
                    newFrame.origin.y = initialFrame.maxY - newFrame.height
                }
            case .bottom:
                newFrame.size.height = max(initialFrame.height - deltaY, 100)
                newFrame.origin.y = initialFrame.maxY - newFrame.height
            case .left, .bottomLeft:
                let newWidth = max(initialFrame.width - deltaX, 100)
                newFrame.origin.x = initialFrame.maxX - newWidth
                newFrame.size.width = newWidth
                if resizeEdge == .bottomLeft {
                    newFrame.size.height = max(initialFrame.height - deltaY, 100)
                    newFrame.origin.y = initialFrame.maxY - newFrame.height
                }
            case .top, .topLeft, .topRight:
                newFrame.size.height = max(initialFrame.height + deltaY, 100)
                if resizeEdge == .topLeft || resizeEdge == .topRight {
                    let newWidth = resizeEdge == .topLeft ? max(initialFrame.width - deltaX, 100) : max(initialFrame.width + deltaX, 100)
                    newFrame.origin.x = resizeEdge == .topLeft ? initialFrame.maxX - newWidth : initialFrame.minX
                    newFrame.size.width = newWidth
                }
            case .none:
                break
            }

            window.setFrame(newFrame, display: true)
            settings.width = newFrame.width
            settings.height = newFrame.height

            os_log("Resizing - New frame: %{public}@",
                   log: logger,
                   type: .debug,
                   String(describing: newFrame))
        }
    }

    override func mouseUp(with event: NSEvent) {
        isResizing = false
        isDragging = false
        initialMouseLocation = nil
        initialFrame = nil
        resizeEdge = .none

        os_log("Mouse Up", log: logger, type: .debug)
    }

    override func mouseMoved(with event: NSEvent) {
        guard self.window != nil else { return }
        let location = self.convert(event.locationInWindow, from: nil)
        let resizeMargin: CGFloat = 5.0

        let isLeft = location.x < resizeMargin
        let isRight = location.x > bounds.width - resizeMargin
        let isTop = location.y > bounds.height - resizeMargin
        let isBottom = location.y < resizeMargin

        if isLeft && isTop {
            resizeEdge = .topLeft
            NSCursor.crosshair.set()
        } else if isRight && isTop {
            resizeEdge = .topRight
            NSCursor.crosshair.set()
        } else if isLeft && isBottom {
            resizeEdge = .bottomLeft
            NSCursor.crosshair.set()
        } else if isRight && isBottom {
            resizeEdge = .bottomRight
            NSCursor.crosshair.set()
        } else if isLeft || isRight {
            resizeEdge = isLeft ? .left : .right
            NSCursor.resizeLeftRight.set()
        } else if isTop || isBottom {
            resizeEdge = isTop ? .top : .bottom
            NSCursor.resizeUpDown.set()
        } else {
            resizeEdge = .none
            NSCursor.arrow.set()
        }

        os_log("Mouse Moved - location: %{public}@, resizeEdge: %{public}@",
               log: logger,
               type: .debug,
               String(describing: location),
               String(describing: self.resizeEdge))
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        resizeEdge = .none
        os_log("Mouse Exited", log: logger, type: .debug)
    }
}
