
class TimerSequenceCellView < UITableViewCell
  attr_reader :controller

  def init(uuid = nil, name = "New Sequence")
    super().tap do
      @controller = TimerListController.alloc.init(uuid, name)
      @controller.add_name_change_observer(self)
      self.accessoryType = UITableViewCellAccessoryDisclosureIndicator

      self.textLabel.text = @controller.name
    end
  end

  def save
    @controller.save
  end

  def load
    @controller.load
  end

  def name_changed(timer_list_controller)
    self.textLabel.text = @controller.name
  end
end

