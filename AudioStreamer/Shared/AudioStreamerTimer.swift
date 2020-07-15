//
//  AudioStreamerTimer.swift
//  AudioStreamer-iOS
//
//  Created by Victor Kurinny on 5/17/19.
//  Copyright © 2019 Ausome Apps LLC. All rights reserved.
//

import Foundation

class AudioStreamerTimer: NSObject {
    init(timeInterval interval: TimeInterval, repeats: Bool, block: @escaping (AudioStreamerTimer) -> Void) {
        super.init()
        self.block = block
        timer = Timer(timeInterval: interval, target: self, selector: #selector(fired), userInfo: nil, repeats: repeats)
    }

    func invalidate() {
        let strongSelf = self
        strongSelf.block = nil
        strongSelf.timer?.invalidate()
        strongSelf.timer = nil
    }

    fileprivate var timer: Timer?
    private var block: ((AudioStreamerTimer) -> Void)?
}

extension AudioStreamerTimer {
    @objc private func fired() {
        block?(self)
    }
}

extension RunLoop {
    func add(_ audioStreamTimer: AudioStreamerTimer, forMode mode: RunLoop.Mode) {
        guard let timer = audioStreamTimer.timer else { return }

        add(timer, forMode: mode)
    }
}
