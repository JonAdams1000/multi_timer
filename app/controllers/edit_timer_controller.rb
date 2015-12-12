
class EditTimerController < UIViewController
  def viewDidLoad
    view.backgroundColor = UIColor.whiteColor
    @picker = UIPickerView.alloc.init
    @picker.dataSource = self
    @picker.delegate = self
    @picker.center = view.center
    @minutes = minutes
    @seconds = seconds
    @picker.selectRow(@minutes, inComponent:0, animated: false)
    @picker.selectRow(@seconds, inComponent:1, animated: false)
    view.addSubview(@picker)

    @done = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemDone, target:self, action:'update_timer')
    navigationItem.rightBarButtonItem = @done
  end

  def timer=(timer)
    @timer = timer
  end

  def hidesBottomBarWhenPushed
    true
  end

  # Data source methods
  def numberOfComponentsInPickerView(picker_view)
    2
  end

  def pickerView(picker_view, numberOfRowsInComponent:component)
    60
  end

  # Delegate methods
  def pickerView(pickerView, didSelectRow:row, inComponent:component)
    if component == 0
      @minutes = row
    elsif component == 1
      @seconds = row
    end
    if @minutes == 0 && @seconds == 0
      @done.enabled = false
    else
      @done.enabled = true
    end
  end

  def pickerView(pickerView, titleForRow:row, forComponent:component)
    return "%02d" % [row]
  end

  private
  def update_timer
    new_time = (@minutes * 60 + @seconds) * 1000
    @timer.time = new_time
    navigationController.popViewControllerAnimated(true)
    timer_list_controller = navigationController.viewControllers.find {|c| c.is_a? TimerListController }
    timer_list_controller.save
  end

  # These next two methods do not belong here.
  def minutes
    total_seconds = @timer.time / 1000
    return (total_seconds / 60).to_i
  end

  def seconds
    total_seconds = @timer.time / 1000
    return total_seconds % 60
  end
end

