import UIKit

// Using a Semaphore we can block a thread for an arbitrary amount of time, until a signal from another thread is sent.

typealias DoneBlock = () -> Void
typealias WorkBlock = (DoneBlock) -> Void

class AsyncSerialWorker {
    private let serialQueue = DispatchQueue(label: "com.applinco.serial.queue")
    func enqueueWork(work: @escaping WorkBlock) {
        serialQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            work { semaphore.signal() }
            semaphore.wait()
        }
    }
}

// Limiting the # of concurrent blocks, previously semaphore used as a simple flag, BUT can also use it a counter for finite resources. If you want to only open a certain # of connections to a specific resource, you can nuse something like the code below:

class LimitedWorker {
    private let serialQueue = DispatchQueue(label: "com.applinco.serial.queue")
    private let concurrentQueue = DispatchQueue(label: "com.applinco.serial.queue", attributes: .concurrent)
    private let semaphore: DispatchSemaphore
    
    init(limit: Int) {
        semaphore = DispatchSemaphore(value: limit)
    }
    
    func enqueue(task: @escaping () -> Void) {
        serialQueue.async {
            self.semaphore.wait()
            self.concurrentQueue.async(execute: {
                task()
                self.semaphore.signal()
            })
        }
    }
}

func performExtensiveWork(item: Int, competionBlock: (() -> Void)? = nil) {
    
}

// Wait for many concurrent tasks to finish

// This is a great case for flattening a function that has a completion block. The dispatch group considers the block to be completed when it returns, so you need the block to wait until the work is complete.
let backgroundQueue = DispatchQueue(label: "com.applinco.serial.queue", attributes: .concurrent)
let group = DispatchGroup()
let someArray = [1,2,3]
for item in someArray {
    backgroundQueue.async(group: group, execute: DispatchWorkItem(block: {
        performExtensiveWork(item: item)
    }))
}

group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
    // work is complete
}))

// A more manual way
let group2 = DispatchGroup()
for item in someArray {
    group.enter()
    performExtensiveWork(item: item, competionBlock: {
        group2.leave()
    })
}
group.wait()
// all work is complete


// Isolation Queues - can be used to achieve thread-safety. Example use is when a value type (Dict, Array) get modified, updating instance variables on Swift objects is not atomic, they are not thread safe

// IdentityMap is a dict that past items from their ID to the model object

protocol Identifiable {
    var id: String { get }
}

class IdentityMap<T: Identifiable> {
    var dictionary = Dictionary<String, T>()
    
    private let accessQueue = DispatchQueue(label: "com.applinco.serial.queue", attributes: .concurrent)
    
    func object(forID id: String) -> T? {
        return accessQueue.sync {
            return dictionary[id] as T?
        }
    }
    
    func addObject(object: T) {
        accessQueue.async(flags: .barrier, execute: {
            self.dictionary[object.id] = object
        })
    }
}

func extensiveWorkPart1() {
    
}

func extensiveWorkPart2() {
    
}
// Cancelling blocks
var work: DispatchWorkItem?
work = DispatchWorkItem(block: {
    extensiveWorkPart1()
    if work?.isCancelled ?? false { return }
    extensiveWorkPart2()
})

/*
 Timer Dispatch Sources
 Dispatch sources are a weird thing, and if you’ve made it this far in the handbook, you’ve reached some pretty esoteric stuff. With dispatch sources, you set up a callback up when initializing the dispatch source, and which in triggered when specific events happen. The simplest of these events is a timed event. A simple dispatch timer could be set up like so:
 */
class Timer {
    let timer = DispatchSource.makeTimerSource(queue: .main)
    
    init(onFire: @escaping () -> Void, interval: DispatchTimeInterval, leeway: DispatchTimeInterval = .milliseconds(500)) {
        timer.schedule(deadline: DispatchTime.now(), repeating: interval, leeway: leeway)
        timer.setEventHandler(handler: onFire)
        timer.resume()
    }
}


/*
 
 Custom Dispatch Sources
 Another useful type of dispatch source is a custom dispatch source. With a custom dispatch source, you can trigger it any time you want. The dispatch source will coalesce the signals that you send it, and periodically call your event handler. I couldn’t find anything in the documentation defining the policy that guides this coalescing. Here’s an example of an object that adds up data sent in from different threads:
 
 */

class DataAdder {
    let source = DispatchSource.makeUserDataAddSource(queue: .main)
    
    init(onFire: @escaping)
}
