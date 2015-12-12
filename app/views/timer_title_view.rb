
class TimerTitleView < UITextField
  def init(title, parent)
    initWithFrame(CGRectMake(0, 0, 200, 22)).tap do
      @parent = parent
      self.text = title
      self.font = UIFont.boldSystemFontOfSize(19)
      self.textColor = UIColor.blackColor
      self.textAlignment = NSTextAlignmentCenter
      self.setReturnKeyType(UIReturnKeyDone)
      self.delegate = self
    end
  end

  # Delegate methods
  def textFieldDidEndEditing(text_field)
    @parent.name = self.text
  end

  def textFieldShouldReturn(text_field)
    self.resignFirstResponder
    return true
  end
  # End of delegate methods

  private
  def finished
  end
end

