
class Timer
  attr_reader :uuid, :time, :chained_timers

  def initialize(time, &finished_action)
    @time = time
    @elapsed_time_after_start = 0
    @total_elapsed_time = 0
    @parent_time = 0
    @finished_action = finished_action
    @chained_timers = []
    @uuid = NSUUID.UUID.UUIDString
  end

  def view=(view)
    @view = WeakRef.new(view)
  end

  def time=(time)
    @time = time
    updated_parent_time_on_chained_timers
    inform_view
  end

  def reset
    @finished = false
    @elapsed_time_after_start = 0
    @total_elapsed_time = 0
    inform_view
  end

  def tick increment, run_finish_action = true
    @total_elapsed_time += increment
    inform_view
    if @total_elapsed_time >= total_time
      @finished = true
      @finished_action.call if @finished_action && run_finish_action
    end
  end

  def remaining_time
    remaining = total_time - @total_elapsed_time
    remaining > @time ? @time : remaining
  end

  def add_chained_timer(timer)
    @chained_timers << timer
    timer.parent_time = parent_time_for_chained_timer
  end

  def finished?
    @finished
  end

  def time_till_finished
    time = total_time - @total_elapsed_time
    time < 0 ? 0 : time # Don't ever return a negative number
  end

  def has_chained_timers?
    ! @chained_timers.empty?
  end

  def is_chained_timer?(timer)
    @chained_timers.include?(timer)
  end

  def remove_chained_timer(timer)
    @chained_timers.delete_if {|t| t == timer }
  end

  def to_hash
    {time: @time, uuid: @uuid}
  end

  protected
  def parent_time=(parent_time)
    @parent_time = parent_time
    updated_parent_time_on_chained_timers
  end

  private
  def inform_view
    @view.timer_changed if @view
  end

  def total_time
    @parent_time + @time
  end

  def updated_parent_time_on_chained_timers
    @chained_timers.each {|t| t.parent_time = parent_time_for_chained_timer }
  end

  def parent_time_for_chained_timer
    @time + @parent_time
  end
end

