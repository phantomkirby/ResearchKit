/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Ricardo Sánchez-Sáez.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice, 
 this list of conditions and the following disclaimer in the documentation and/or 
 other materials provided with the distribution. 
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
 may be used to endorse or promote products derived from this software without 
 specific prior written permission. No license is granted to the trademarks of 
 the copyright holders even if such marks are included in this software. 
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

import UIKit
import ResearchKit

/**
    This example displays a catalog of tasks, each consisting of one or two steps,
    built using the ResearchKit framework. The `TaskListViewController` displays the
    available tasks in this catalog.

    When you tap a task, it is presented like a participant in a study might
    see it. After completing the task, you can see the results generated by
    the task by switching to the results tab.
*/
class TaskListViewController: UITableViewController, ORKTaskViewControllerDelegate {
    
    var waitStepViewController: ORKWaitStepViewController?
    var waitStepUpdateTimer: NSTimer?
    var waitStepProgress: CGFloat = 0.0
    
    // MARK: Types
    
    enum TableViewCellIdentifier: String {
        case Default = "Default"
    }
    
    // MARK: Properties
    
    /**
        When a task is completed, the `TaskListViewController` calls this closure
        with the created task.
    */
    var taskResultFinishedCompletionHandler: (ORKResult -> Void)?
    
    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TaskListRow.sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TaskListRow.sections[section].rows.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return TaskListRow.sections[section].title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifier.Default.rawValue, forIndexPath: indexPath)
        
        let taskListRow = TaskListRow.sections[indexPath.section].rows[indexPath.row]
        
        cell.textLabel!.text = "\(taskListRow)"
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // Present the task view controller that the user asked for.
        let taskListRow = TaskListRow.sections[indexPath.section].rows[indexPath.row]
        
        // Create a task from the `TaskListRow` to present in the `ORKTaskViewController`.
        let task = taskListRow.representedTask
        
        /*
            Passing `nil` for the `taskRunUUID` lets the task view controller
            generate an identifier for this run of the task.
        */
        let taskViewController = ORKTaskViewController(task: task, taskRunUUID: nil)

        // Make sure we receive events from `taskViewController`.
        taskViewController.delegate = self
        
        // Assign a directory to store `taskViewController` output.
        taskViewController.outputDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!

        /*
            We present the task directly, but it is also possible to use segues.
            The task property of the task view controller can be set any time before
            the task view controller is presented.
        */
        presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        /*
            The `reason` passed to this method indicates why the task view
            controller finished: Did the user cancel, save, or actually complete
            the task; or was there an error?

            The actual result of the task is on the `result` property of the task
            view controller.
        */
        taskResultFinishedCompletionHandler?(taskViewController.result)

        taskViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func taskViewController(taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        // Example data processing for the wait step.
        if stepViewController.step?.identifier == "WaitStepIndeterminate" {
            delay(5.0, closure: { () -> () in
                if let stepViewController = stepViewController as? ORKWaitStepViewController {
                    stepViewController.goForward()
                }
            })
        } else if stepViewController.step?.identifier == "WaitStepDeterminate" {
            delay(1.0, closure: { () -> () in
                if let stepViewController = stepViewController as? ORKWaitStepViewController {
                    self.waitStepViewController = stepViewController;
                    self.waitStepProgress = 0.0
                    self.waitStepUpdateTimer = NSTimer(timeInterval: 0.1, target: self, selector: "updateProgressOfWaitStepViewController", userInfo: nil, repeats: true)
                    NSRunLoop.mainRunLoop().addTimer(self.waitStepUpdateTimer!, forMode: NSRunLoopCommonModes)
                }
            })
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func updateProgressOfWaitStepViewController() {
        if let waitStepViewController = waitStepViewController {
            waitStepProgress += 0.01
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                waitStepViewController.setProgress(self.waitStepProgress, animated: true)
            })
            if (waitStepProgress < 1.0) {
                return
            } else {
                self.waitStepUpdateTimer?.invalidate()
                waitStepViewController.goForward()
                self.waitStepViewController = nil
            }
        } else {
            self.waitStepUpdateTimer?.invalidate()
        }
    }

}
