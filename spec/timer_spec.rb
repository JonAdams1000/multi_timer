
describe Timer do
  before do
    @timer = Timer.new(10)
  end

  it "finishes once enough time has passed" do
    @timer.tick(10)
    @timer.should.be.finished
  end

  it "should reset when stopped" do
    @timer.tick(5)
    @timer.reset
    @timer.tick(5)
    @timer.should.not.be.finished
  end

  it "should trigger action when finshed" do
    finished = false
    timer = Timer.new(10) do
      finished = true
    end
    timer.tick(10)
    finished.should.be.true
  end

  it "does not trigger action when finishing if told not to" do
    finished = false
    timer = Timer.new(10) do
      finished = true
    end
    timer.tick(10, false)
    finished.should.not.be.true
  end

  it "should return remaining time" do
    @timer.remaining_time.should == 10
    @timer.tick(5)
    @timer.remaining_time.should == 5
  end

  it "informs view of update to remaining time" do
    mock_view = Object.new
    mock_view.mock!(:timer_changed)

    @timer.view = mock_view

    @timer.tick(5)
  end

  it "informs view when timer is stopped" do
    mock_view = Object.new
    mock_view.mock!(:timer_changed)

    @timer.view = mock_view

    @timer.reset
  end

  it "can have its time changed" do
    @timer.remaining_time.should == 10
    @timer.time = 100
    @timer.remaining_time.should == 100
  end

  it "informs view when time is changed" do
    mock_view = Object.new
    mock_view.mock!(:timer_changed)

    @timer.view = mock_view

    @timer.time = 100
  end

  it "includes its parent time in the total amount of time till finished" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    parent_timer.time_till_finished.should == 100
    chained_timer.time_till_finished.should == 200
  end

  it "gives the correct time till finished even after starting" do
    parent_timer = Timer.new(100)

    parent_timer.tick(50)

    parent_timer.time_till_finished.should == 50
  end

  it "gives the correct time till finished when the parent has started but it hasn't" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)

    parent_timer.tick(50)
    chained_timer.tick(50)

    parent_timer.time_till_finished.should == 50
    chained_timer.time_till_finished.should == 150
  end

  it "gives the correct time till finished after it has been started by the parent" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)

    parent_timer.tick(100)
    chained_timer.tick(100)

    parent_timer.tick(50)
    chained_timer.tick(50)

    parent_timer.time_till_finished.should == 0
    chained_timer.time_till_finished.should == 50
  end

  it "gives the correct time till finished even as a grandchild" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    grandchild_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    chained_timer.add_chained_timer(grandchild_timer)
    parent_timer.time_till_finished.should == 100
    chained_timer.time_till_finished.should == 200
    grandchild_timer.time_till_finished.should == 300
  end

  it "informs chained timers when its time is changed" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    parent_timer.time = 200
    parent_timer.time_till_finished.should == 200
    chained_timer.time_till_finished.should == 300
  end

  it "informs chained timers when its parents time has changed" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    grandchild_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    chained_timer.add_chained_timer(grandchild_timer)
    parent_timer.time = 200
    parent_timer.time_till_finished.should == 200
    chained_timer.time_till_finished.should == 300
    grandchild_timer.time_till_finished.should == 400
  end

  it "updates remaining time correctly when given increment that covers parent time" do
    timer = Timer.new(100)
    timer.send :parent_time=, 100
    timer.tick(150)
    timer.remaining_time.should == 50
  end

  it "updates parent time on chained timers correctly when its time is changed" do
    parent_timer = Timer.new(100)
    parent_timer.send :parent_time=, 100
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    parent_timer.time_till_finished.should == 200
    chained_timer.time_till_finished.should == 300
    parent_timer.time = 200
    parent_timer.time_till_finished.should == 300
    chained_timer.time_till_finished.should == 400
  end

  it "recognises chained timer as its own" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    parent_timer.is_chained_timer?(chained_timer).should.be.true
  end

  it "rejects chained timer when not its own" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.is_chained_timer?(chained_timer).should.be.false
  end

  it "removes chained timer" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    parent_timer.is_chained_timer?(chained_timer).should.be.true
    parent_timer.remove_chained_timer(chained_timer)
    parent_timer.is_chained_timer?(chained_timer).should.be.false
  end

  it "returns hash containing timer details" do
    timer = Timer.new(100)
    timer.to_hash.should == {time: 100, uuid: timer.uuid}
  end
end

