
describe Clock do
  before do
    @clock = Clock.new
    #stub_out_timer
  end

  it "starts timers when told to" do
    expect_timer_to_be_started
    timer = Timer.new(10)
    @clock.add_primary_timer(timer)
    @clock.start_timers
  end

  it "stops timer when told to" do
    expect_timer_to_be_started
    @mock_timer.mock!(:invalidate)
    timer = Timer.new(200)
    @clock.add_primary_timer(timer)
    @clock.start_timers
    @clock.send :timerFired # Move timer on
    @clock.stop_timers
    timer.remaining_time.should == 200 # Timer has been reset
  end

  it "pauses timer when told to" do
    expect_timer_to_be_started
    @mock_timer.mock!(:invalidate)
    timer = Timer.new(10)
    @clock.add_primary_timer(timer)
    @clock.start_timers
    # Move the timer on a bit so we can check it has been paused and not stopped
    timer.tick(5) 
    @clock.pause_timers
    timer.remaining_time.should == 5
  end

  it "stops all timers, including chained timers" do
    expect_timer_to_be_started
    @mock_timer.mock!(:invalidate)
    main_timer = Timer.new(10)
    chained_timer = Timer.new(10)
    @clock.add_primary_timer(main_timer)
    @clock.add_chained_timer(chained_timer)
    @clock.start_timers
    chained_timer.tick(5) # Move on
    @clock.stop_timers
    chained_timer.remaining_time.should == 10 # It has been reset
  end

  it "stops timer when entering background" do
    timer = Object.new
    timer.mock!(:invalidate)

    @clock.instance_variable_set(:@clock, timer)
    @clock.entering_background
  end

  it "restarts clock and updates timers when entering foreground" do
    mock_timer = Object.new
    NSTimer.mock!(:"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats") do |interval, target, selector, userInfo, repeats|
      interval.should == 0.1
      target.should == @clock
      selector.should == "timerFired"
      userInfo.should.be.nil
      repeats.should == true
      mock_timer # This is the return value of the mocked method.
    end
    NSRunLoop.mainRunLoop.mock!(:"addTimer:forMode") do |loop_timer, mode|
      loop_timer.should == mock_timer
      mode.should == NSRunLoopCommonModes
    end

    timer = Timer.new(100)
    @clock.add_primary_timer(timer)
    @clock.start_timers
    @clock.entering_foreground_after(50)
    timer.remaining_time.should == 50
  end

  it "restarts clock and updates timers when entering foreground including chained timers" do
    mock_timer = Object.new
    NSTimer.mock!(:"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats") do |interval, target, selector, userInfo, repeats|
      interval.should == 0.1
      target.should == @clock
      selector.should == "timerFired"
      userInfo.should.be.nil
      repeats.should == true
      mock_timer # This is the return value of the mocked method.
    end
    NSRunLoop.mainRunLoop.mock!(:"addTimer:forMode") do |loop_timer, mode|
      loop_timer.should == mock_timer
      mode.should == NSRunLoopCommonModes
    end

    timer = Timer.new(100)
    chained_timer = Timer.new(100)
    timer.add_chained_timer(chained_timer)
    @clock.add_primary_timer(timer)
    @clock.start_timers
    @clock.entering_foreground_after(50)
    timer.remaining_time.should == 50
    chained_timer.remaining_time.should == 100
  end

  it "restarts clock and updates timers when entering foreground including starting chained timers" do
    mock_timer = Object.new
    NSTimer.mock!(:"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats") do |interval, target, selector, userInfo, repeats|
      interval.should == 0.1
      target.should == @clock
      selector.should == "timerFired"
      userInfo.should.be.nil
      repeats.should == true
      mock_timer # This is the return value of the mocked method.
    end
    NSRunLoop.mainRunLoop.mock!(:"addTimer:forMode") do |loop_timer, mode|
      loop_timer.should == mock_timer
      mode.should == NSRunLoopCommonModes
    end

    timer = Timer.new(100)
    chained_timer = Timer.new(100)
    timer.add_chained_timer(chained_timer)
    @clock.add_primary_timer(timer)
    @clock.add_primary_timer(chained_timer)
    @clock.start_timers
    @clock.entering_foreground_after(150)
    timer.should.be.finished
    chained_timer.remaining_time.should == 50
  end

  it "informs finished timers not to trigger finishing action when entering foreground" do
    finished = false
    timer = Timer.new(100) do
      finished = true
    end
    @clock.add_primary_timer(timer)
    @clock.start_timers
    @clock.entering_foreground_after(200, [timer.uuid])
    finished.should.not.be.true
  end

  it "returns a list of when all timers will finish" do
    primary_timer1 = Timer.new(100)
    primary_timer2 = Timer.new(200)
    chained_timer = Timer.new(50)
    primary_timer1.add_chained_timer(chained_timer)
    @clock.add_primary_timer(primary_timer1)
    @clock.add_primary_timer(primary_timer2)
    @clock.add_chained_timer(chained_timer)

    @clock.start_timers

    times = @clock.remaining_times
    times.sort.should == [100, 150, 200]
  end

  it "can remove a timer" do
    timer = Timer.new(100)
    @clock.add_primary_timer(timer)
    @clock.remove_timer(timer.uuid)
    @clock.timers.should.be.empty
  end

  it "updates chained timer when parent is removed" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    chained_timer.time_till_finished.should == 200
    @clock.add_primary_timer(parent_timer)
    @clock.add_chained_timer(chained_timer)
    @clock.remove_timer(parent_timer.uuid)
    chained_timer.time_till_finished.should == 100 # No longer includes the parents time
  end

  it "updates parent when chained timer is removed" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    @clock.add_primary_timer(parent_timer)
    @clock.add_chained_timer(chained_timer)
    @clock.remove_timer(chained_timer.uuid)
    parent_timer.should.not.has_chained_timers
  end

  it "moves grandchild timers to parent when removing a chained timer" do
    parent_timer = Timer.new(100)
    chained_timer = Timer.new(100)
    grandchild_timer = Timer.new(100)
    parent_timer.add_chained_timer(chained_timer)
    chained_timer.add_chained_timer(grandchild_timer)
    @clock.add_primary_timer(parent_timer)
    @clock.add_chained_timer(chained_timer)
    @clock.add_chained_timer(grandchild_timer)
    parent_timer.is_chained_timer?(grandchild_timer).should.be.false
    grandchild_timer.time_till_finished.should == 300
    @clock.remove_timer(chained_timer.uuid)
    parent_timer.should.has_chained_timers
    parent_timer.is_chained_timer?(grandchild_timer).should.be.true
    grandchild_timer.time_till_finished.should == 200
  end

  def stub_out_timer
    NSTimer.stub!(:"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats") {|time, target, selector, user_info, repeats| }
    NSRunLoop.mainRunLoop.stub!(:"addTimer:forMode") {|timer, mode| }
  end

  def expect_timer_to_be_started
    @mock_timer = Object.new
    NSTimer.mock!(:"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats") do |interval, target, selector, userInfo, repeats|
      interval.should == 0.1
      target.should == @clock
      selector.should == "timerFired"
      userInfo.should.be.nil
      repeats.should == true
      @mock_timer # This is the return value of the mocked method.
    end
    NSRunLoop.mainRunLoop.mock!(:"addTimer:forMode") do |loop_timer, mode|
      loop_timer.should == @mock_timer
      mode.should == NSRunLoopCommonModes
    end
    # Mock out the async calls to make is synchronous.
    mock_queue = Object.new
    Dispatch::Queue.mock!(:main, return: mock_queue)
    mock_queue.mock!(:async, yield: [])
  end
end

