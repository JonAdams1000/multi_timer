
class MainViewController < UINavigationController
  def init
    initWithNavigationBarClass(nil, toolbarClass: nil).tap do
      self.delegate = self
    end
  end
  def viewDidLoad
    super
    setToolbarHidden(false, animated:false)
  end

  def display_timer_picker(timer)
    controller = EditTimerController.alloc.init
    controller.timer = timer
    self.pushViewController(controller, animated: true)
  end

  # Delegate methods
  def navigationController(navigation_controller, willShowViewController:view_controller, animated:animated)
    if view_controller.is_a?(TimerSequenceListController) && visibleViewController.is_a?(TimerListController)
      # Moving from a timer sequence back to main page
      if visibleViewController.running?
        visibleViewController.stop
      end
    end
  end
  # End of delegate methods
end
