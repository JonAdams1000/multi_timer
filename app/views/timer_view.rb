
class TimerView < UITableViewCell
  attr_reader :timer

  def init
    super.tap do
      @remaining_time = self.textLabel
      @remaining_time.accessibilityLabel = 'remaining_time'
      @remaining_time.text = 'Timer'

      @edit = UIButton.buttonWithType(UIButtonTypeSystem)
      @edit.setTitle('Edit', forState:UIControlStateNormal)
      @edit.backgroundColor = UIColor.lightGrayColor
      edit_button_width = 40
      @edit.frame = [[frame.size.width - 40, 0], [edit_button_width, 40]]
      @edit.addTarget(self, action:'edit_timer', forControlEvents:UIControlEventTouchUpInside)
      addSubview(@edit)

      @create = UIButton.buttonWithType(UIButtonTypeSystem)
      @create.setTitle('Chain', forState:UIControlStateNormal)
      @create.backgroundColor = UIColor.lightGrayColor
      create_button_width = 40
      @create.frame = [[frame.size.width - (edit_button_width + 50), 0], [create_button_width, 40]]
      @create.addTarget(self, action:'create_chained_timer', forControlEvents:UIControlEventTouchUpInside)
      addSubview(@create)

      self.accessoryType = UITableViewCellAccessoryDisclosureIndicator
    end
  end

  def set_timer(timer)
    @timer = timer
    @timer.view = self
    update_remaining_time
  end

  def timer_changed
    update_remaining_time
  end

  def timer_uuid
    timer.uuid if timer
  end

  def timer_started
    @create.enabled = false
    @edit.enabled = false
  end

  def timer_stopped
    @create.enabled = true
    @edit.enabled = true
  end

  def reveal_chain_button
    @create.hidden = false
  end

  def hide_chain_button
    @create.hidden = true
  end

  def edit_timer
    controller = self.superview.nextResponder
    until controller.is_a? MainViewController || controller.nil?
      controller = controller.nextResponder
    end
    # TODO: Handle case when controller is nil - should never happen!
    controller.display_timer_picker(@timer)
  end

  private
  def update_remaining_time
    remaining_time = @timer.remaining_time
    @remaining_time.text = prepare_label_text(remaining_time)
  end

  def prepare_label_text(remaining_time)
    # Under certain circumstances (e.g., returning from the background),
    # remaining_time can actually be negative. In this case always show
    # zero time remaining.
    return "00:00.0" if remaining_time <= 0
    time_in_seconds = remaining_time / 1000
    milliseconds = (remaining_time % 1000) / 100
    minutes = time_in_seconds / 60
    seconds = time_in_seconds % 60
    output = "%02d:%02d.%d" % [minutes, seconds, milliseconds]
  end

  def create_chained_timer
    controller = timer_list_controller
    controller.add_chained_timer(self)
    hide_chain_button # Only allow a single chained timer.
    controller.save
  end

  def timer_list_controller
    controller = self.superview.nextResponder
    until controller.is_a? TimerListController || controller.nil?
      controller = controller.nextResponder
    end
    controller
  end
end

