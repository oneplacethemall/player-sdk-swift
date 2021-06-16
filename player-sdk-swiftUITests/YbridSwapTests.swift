//
// YbridSwapTests.swift
// player-sdk-swift
//
// Copyright (c) 2021 nacamar GmbH - Ybrid®, a Hybrid Dynamic Live Audio Technology
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import XCTest
import YbridPlayerSDK

class YbridSwapTests: XCTestCase {

    var control:YbridControl?
    let ybridPlayerListener = TestYbridPlayerListener()
    var semaphore:DispatchSemaphore?
    
    let poller = Poller()
    override func setUpWithError() throws {
        // don't log additional debug information in this tests
        Logger.verbose = false
        ybridPlayerListener.reset()
        semaphore = DispatchSemaphore(value: 0)
    }
    
    override func tearDownWithError() throws {
        let errors = ybridPlayerListener.errors.map{ $0.localizedDescription }
        print( "errors were \(errors)")
    }

    func test01_SwapItem_SwapItem() throws {
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: ybridPlayerListener,
                playbackControl: { [self] (control) in
                    XCTFail("ybridControl expected");semaphore?.signal()
                },
                ybridControl: { [self] (ybridControl) in
                
                ybridControl.play()
                poller.wait(ybridControl, until: PlaybackState.playing, maxSeconds: 10)
                sleep(2)
                guard let titleMain = ybridPlayerListener.metadatas.last?.displayTitle else {
                    XCTFail("must have recieved metadata");
                    semaphore?.signal(); return
                }
                print("title main =\(titleMain)")
                
                var titleSwapped:String?
                ybridControl.swapItem(nil)
                _ = poller.wait(max: 10) {
                    guard let swapped = ybridPlayerListener.metadatas.last?.displayTitle else {
                        return false
                    }
                    titleSwapped = swapped
                    print("title swapped =\(titleSwapped!)")
                    return titleMain != titleSwapped!
                }
                sleep(2)
                
                ybridControl.swapItem(nil)
                _ = poller.wait(max: 10) {
                    guard let titleSwapped2 = ybridPlayerListener.metadatas.last?.displayTitle else {
                        return false
                    }
                    print("title swapped =\(titleSwapped2)")
                    return titleSwapped2 != titleSwapped
                }
                sleep(2)
 
                    
                ybridControl.stop()
                poller.wait(ybridControl, until: PlaybackState.stopped, maxSeconds: 2)
                
                semaphore?.signal()
               })
        _ = semaphore?.wait(timeout: .distantFuture)
        
        let titles:[String] =
        ybridPlayerListener.metadatas.map{ $0.displayTitle ?? "(nil)"}
        print( "titles were \(titles)")
        
        XCTAssertTrue((3...4).contains(ybridPlayerListener.metadatas.count), "should be 3 (4 if item changed) metadata changes, but were \(ybridPlayerListener.metadatas.count)")
    }

    
    func test02_AvailableServices_BeforePlay() throws {
        XCTAssertEqual(0,ybridPlayerListener.services.count)
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: ybridPlayerListener,
               playbackControl: { [self] (control) in
                    XCTFail("ybridControl expected"); semaphore?.signal()
               },
               ybridControl: { [self] (ybridControl) in
                    semaphore?.signal()
               })
        _ = semaphore?.wait(timeout: .distantFuture)
        XCTAssertEqual(1,ybridPlayerListener.services.count)
        XCTAssertEqual(2,ybridPlayerListener.services[0].count)
        
        XCTAssertEqual(0,ybridPlayerListener.metadatas.count)
    }
    
    func test03_SwapService_BeforePlay() throws {
        Logger.verbose = true
        XCTAssertEqual(0,ybridPlayerListener.services.count)
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: ybridPlayerListener,
               playbackControl: { [self] (control) in
                     XCTFail("ybridControl expected"); semaphore?.signal()
               },
               ybridControl: { [self] (ybridControl) in

                ybridControl.swapService(to: "ad-injection-demo", nil)
                sleep(2)
                
                ybridControl.play()
                _ = poller.wait(max: 6) {
                    let serviceSwapped = ybridPlayerListener.metadatas.last?.activeService
                    print("service=\(String(describing: serviceSwapped))")
                    return serviceSwapped?.identifier == "ad-injection-demo"
                }
                sleep(2)

               ybridControl.stop()
               poller.wait(ybridControl, until: PlaybackState.stopped, maxSeconds: 2)
                
                semaphore?.signal()
               })
        _ = semaphore?.wait(timeout: .distantFuture)
        
        XCTAssertEqual(1,ybridPlayerListener.services.count)
        XCTAssertEqual(2,ybridPlayerListener.services[0].count)
        
        let services:[String] =
            ybridPlayerListener.metadatas.map{ $0.activeService?.identifier ?? "(nil)"}
        print("services were \(services)")
        
        XCTAssertGreaterThanOrEqual(ybridPlayerListener.metadatas.count, 1)
        XCTAssertEqual("ad-injection-demo",  ybridPlayerListener.metadatas.first?.activeService?.identifier)
        XCTAssertEqual("ad-injection-demo",  ybridPlayerListener.metadatas.last?.activeService?.identifier)
    }
    
    func test04_SwapService_OnPlay() throws {
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: ybridPlayerListener,
               playbackControl: { [self] (control) in
                     XCTFail("ybridControl expected");semaphore?.signal()
               },
               ybridControl: { [self] (ybridControl) in
                
                ybridControl.play()
                poller.wait(ybridControl, until: PlaybackState.playing, maxSeconds: 10)
                let mainService = ybridPlayerListener.metadatas.last?.activeService
                sleep(2)
                
                ybridControl.swapService(to:"ad-injection-demo", nil)
                _ = poller.wait(max: 10) {
                    let serviceSwapped = ybridPlayerListener.metadatas.last?.activeService
                    print("service=\(String(describing: serviceSwapped))")
                    return serviceSwapped?.identifier != mainService?.identifier
                }
                sleep(2)
                         
                ybridControl.stop()
                poller.wait(ybridControl, until: PlaybackState.stopped, maxSeconds: 2)
                
                semaphore?.signal()
               })
        _ = semaphore?.wait(timeout: .distantFuture)
        
        let services:[String] =
            ybridPlayerListener.metadatas.map{ $0.activeService?.identifier ?? "(nil)"}
        print( "services were \(services)")
        
        XCTAssertEqual(services.count, 3, "should be 3 service changes, but were \(services.count)")
    }
    
    func test05_SwapService_AfterStop() throws {
        XCTAssertEqual(0,ybridPlayerListener.services.count)
        try AudioPlayer.open(for: ybridDemoEndpoint, listener: ybridPlayerListener,
               playbackControl: { [self] (control) in
                     XCTFail("ybridControl expected"); semaphore?.signal()
               },
               ybridControl: { [self] (ybridControl) in

                ybridControl.play()
                poller.wait(ybridControl, until: PlaybackState.playing, maxSeconds: 10)
                sleep(2)

               ybridControl.stop()
               poller.wait(ybridControl, until: PlaybackState.stopped, maxSeconds: 2)
                
                ybridControl.swapService(to: "ad-injection-demo", nil)
                sleep(2)
                
                ybridControl.play()
                _ = poller.wait(max: 10) {
                    let serviceSwapped = ybridPlayerListener.metadatas.last?.activeService
                    print("service=\(String(describing: serviceSwapped))")
                    return serviceSwapped?.identifier == "ad-injection-demo"
                }
                sleep(2)
                
                ybridControl.stop()
                poller.wait(ybridControl, until: PlaybackState.stopped, maxSeconds: 2)
                
                semaphore?.signal()
               })
        _ = semaphore?.wait(timeout: .distantFuture)
        
        XCTAssertEqual(1,ybridPlayerListener.services.count)
        XCTAssertEqual(2,ybridPlayerListener.services[0].count)
        
        let services:[String] =
            ybridPlayerListener.metadatas.map{ $0.activeService?.identifier ?? "(nil)"}
        print( "services were \(services)")
        
        XCTAssertEqual("adaptive-demo",  ybridPlayerListener.metadatas.first?.activeService?.identifier)
        XCTAssertEqual("ad-injection-demo",  ybridPlayerListener.metadatas.last?.activeService?.identifier)
    }
}

class Poller {
    
    func wait(_ control:YbridControl, until:PlaybackState, maxSeconds:Int) {
        let took = wait(max: maxSeconds) {
            return control.state == until
        }
        XCTAssertLessThanOrEqual(took, maxSeconds, "not \(until) within \(maxSeconds) s")
    }

    func wait(max maxSeconds:Int, until:() -> (Bool)) -> Int {
        var seconds = 0
        while !until() && seconds <= maxSeconds {
            sleep(1)
            seconds += 1
        }
        XCTAssertTrue(until(), "condition not satisfied within \(maxSeconds) s")
        return seconds
    }

    
    
}


