
describe 'the Timer view' do
  before do
    @view = TimerView.alloc.init
  end

  it "shows remaining time" do
    timer = Timer.new(2000) # Two seconds
    @view.set_timer(timer)
    check_remaining_time_label_shows('00:02.0')
  end

  it "should change remaining time when timer decreases" do
    timer = Timer.new(2000) # Two seconds
    @view.set_timer(timer)
    timer.tick(1000)
    check_remaining_time_label_shows('00:01.0')
  end

  it "should show zero if remaining time is negative" do
    timer = Timer.new(100)
    @view.set_timer(timer)
    timer.tick(1000)
    check_remaining_time_label_shows('00:00.0')
  end

  it "returns uuid for timer" do
    timer = Timer.new(100)
    @view.set_timer(timer)
    @view.timer_uuid.should == timer.uuid
  end

  def check_remaining_time_label_shows(value)
    label = @view.viewByName('remaining_time', 3)
    label.text.should == value
  end
end

