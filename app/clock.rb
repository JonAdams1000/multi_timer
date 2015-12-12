
class Clock
  def initialize
    @timers = []
    @primary_timers = []
    @running = false
  end

  def activate_clock
    Dispatch::Queue.main.async do
      @clock = NSTimer.scheduledTimerWithTimeInterval(0.1, target:self, selector:'timerFired', userInfo:nil, repeats:true)
      NSRunLoop.mainRunLoop.addTimer(@clock, forMode:NSRunLoopCommonModes)
    end
  end

  def stop_clock
    if @clock
      Dispatch::Queue.main.async do
        @clock.invalidate
      end
    end
  end

  def add_primary_timer(timer)
    @timers << timer
    @primary_timers << timer
  end

  def add_chained_timer(timer)
    @timers << timer
  end

  def start_timers
    @running = true
    activate_clock
  end

  def stop_timers
    @running = false
    stop_clock
    @timers.each(&:reset)
  end

  def pause_timers
    @running = false
    stop_clock
  end

  def running?
    @running
  end

  def remaining_times
    @timers.map {|t| t.time_till_finished }
  end

  def entering_background
    stop_clock
  end

  def entering_foreground_after(interval, finished_timers = [])
    return unless running?
    activate_clock
    update_timers(interval, finished_timers)
  end

  def timers
    @timers
  end

  def remove_timer(uuid)
    timer = @timers.find {|t| t.uuid == uuid}
    timer.time = 0 # This should update parent time on all chained timers
    @timers.delete(timer)
    # Find parent timer
    parent_timer = @timers.find {|t| t.is_chained_timer?(timer) }
    if parent_timer
      parent_timer.remove_chained_timer(timer)
      timer.chained_timers.each {|ct| parent_timer.add_chained_timer(ct) }
    end
  end

  private
  def timerFired
    update_timers(100)
    if @timers.reject {|t| t.finished?}.empty?
      # All timers finished
      @running = false
    end
  end

  def update_timers(interval, finished_timers = [])
    @timers.each {|timer| timer.tick(interval, ! finished_timers.include?(timer.uuid)) unless timer.finished? }
  end
end

