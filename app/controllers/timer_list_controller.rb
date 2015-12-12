
class TimerListController < UITableViewController
  FILENAME = "timer_list.json"

  attr_reader :name, :uuid
  def init(uuid = nil, name = "New Sequence")
    initWithStyle(UITableViewStyleGrouped).tap do
      @timers = []
      @running = false
      @clock = Clock.new
      @disable_reload = false
      @name = name
      @uuid = uuid || NSUUID.UUID.UUIDString
      @name_change_observers = []
    end
  end

  def viewDidLoad
    super
    tableView.dataSource = self
    tableView.delegate = self
    tableView.allowsMultipleSelectionDuringEditing = false

    setup_toolbar_buttons

    @title_view = TimerTitleView.alloc.init(name, self)

    navigationItem.backBarButtonItem = UIBarButtonItem.alloc.initWithTitle("Cancel", style:UIBarButtonItemStyleBordered, target:nil, action:nil)
    navigationItem.titleView = @title_view

    if @timers.empty?
      create_timer # Always begin with a single timer.
    end
  end

  def viewWillDisappear(animated)
    save
    if running?
      stop_timers
    end
  end

  def add_name_change_observer(observer)
    @name_change_observers << observer
  end

  def name=(name)
    @name = name
    @name_change_observers.each {|o| o.name_changed(self) }
  end

  def set_clock(clock)
    @clock = clock
  end

  def add_primary_timer(timer_view)
    @timers << [timer_view]
  end

  def reload_table
    view.reloadData unless @disable_reload
  end

  def timers
    @clock.timers
  end

  def running?
    @clock.running?
  end

  def entering_background
    @clock.entering_background
  end

  def entering_foreground_after(interval, fired_timer_uuids)
    @clock.entering_foreground_after(interval, fired_timer_uuids)
  end

  def stop
    stop_timers
  end

  # Data source methods
  def tableView(tableView, cellForRowAtIndexPath:index)
    @timers[index.section][index.row]
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @timers[section].size
  end

  def numberOfSectionsInTableView(tableView)
    @timers.size
  end

  def tableView(tableView, canEditRowAtIndexPath:index)
    # Do not allow deleting the only timer. All others are allowed.
    return !(@timers.size == 1 && @timers[0].size == 1) && !@running
  end

  def tableView(tableView, commitEditingStyle:style, forRowAtIndexPath:index)
    if (style == UITableViewCellEditingStyleDelete)
      timer_view = @timers[index.section][index.row]
      @timers[index.section].delete(timer_view)
      @clock.remove_timer(timer_view.timer_uuid)
      if @timers[index.section].empty?
        @timers.delete_at(index.section)
        tableView.deleteSections(NSIndexSet.indexSetWithIndex(index.section), withRowAnimation:UITableViewRowAnimationFade)
      else
        tableView.deleteRowsAtIndexPaths([index], withRowAnimation:UITableViewRowAnimationAutomatic)
        if @timers[index.section].size == index.row
          # Just deleted the last row in the section
          @timers[index.section].last.reveal_chain_button
        end
      end
      save
    end
  end
  # End of data source methods

  # Delegate methods
  def tableView(tableView, willSelectRowAtIndexPath:index)
    return nil if @running
    timer_view = @timers[index.section][index.row]
    timer_view.edit_timer
    return nil
  end
  # End of delegate methods

  def add_chained_timer(timer_view, seconds = 60000)
    # First, find the section containing this timer
    section = @timers.find {|section| section.include?(timer_view) }
    chained_timer_view = create_timer_view(seconds)
    chained_timer = chained_timer_view.timer
    section << chained_timer_view
    @clock.add_chained_timer(chained_timer)
    timer_view.timer.add_chained_timer(chained_timer)
    reload_table
    chained_timer_view
  end

  def save
    hashed_timers = @timers.map do |section|
      section.map { |timer_view| timer_view.timer.to_hash}
    end
    string = BW::JSON.generate(hashed_timers)
    puts "Saving:"
    puts string
    puts "to #{file_path}"
    NSFileManager.defaultManager.createFileAtPath(file_path, contents:string.dataUsingEncoding(NSUTF8StringEncoding), attributes:nil)
  end

  def load
    return unless NSFileManager.defaultManager.fileExistsAtPath(file_path)
    @disable_reload = true # Avoid reloading table for every timer.
    content = NSString.alloc.initWithData(NSFileManager.defaultManager.contentsAtPath(file_path), encoding:NSUTF8StringEncoding)
    hashed_timers = BW::JSON.parse(content)
    hashed_timers.each do |section|
      # The first timer needs to be added as a primary timer, any others as chained timers.
      timer_view = create_timer(section.first[:time])
      load_chained_timer(timer_view, section[1..-1])
    end
    @disable_reload = false
    reload_table # Now reload.
  end

  def delete
    error_ptr = Pointer.new(:object)
    # TODO Handle errors!
    NSFileManager.defaultManager.removeItemAtPath(file_path, error:error_ptr)
  end

  private
  def load_chained_timer(parent_view, chained_timer_list)
    return if chained_timer_list.empty?
    chained_timer_view = add_chained_timer(parent_view, chained_timer_list.first[:time])
    parent_view.hide_chain_button
    load_chained_timer(chained_timer_view, chained_timer_list[1..-1])
  end

  def create_new_timer
    create_timer
    save
  end

  def create_timer(seconds = 60000)
    timer_view = create_timer_view(seconds)
    add_primary_timer(timer_view)
    @clock.add_primary_timer(timer_view.timer)
    reload_table
    timer_view
  end

  def create_timer_view(seconds)
    timer_view = TimerView.alloc.init
    timer = Timer.new(seconds) do
      puts "New timer has finished!"
      2.times do
        AudioServicesPlaySystemSound(KSystemSoundID_Vibrate)
      end
    end
    timer_view.set_timer(timer)
    timer_view
  end

  def start_timers
    @running = true
    @create.enabled = false
    @timers.each do |section|
      section.each(&:timer_started)
    end
    @clock.start_timers
  end

  def stop_timers
    @running = false
    @create.enabled = true
    @timers.each do |section|
      section.each(&:timer_stopped)
    end
    @clock.stop_timers
  end

  def reset_timers
    stop_timers if running?
    @timers = [] # Clear all
    create_timer # Add one timer
    reload_table
    save
  end

  def setup_toolbar_buttons
    buttons = []
    @start = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemPlay, target:self, action:'start_timers')
    buttons << @start

    @stop = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemStop, target:self, action:'stop_timers')
    buttons << @stop

    @create = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemAdd, target:self, action:'create_new_timer')
    navigationItem.rightBarButtonItem = @create

    @reset = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemRefresh, target:self, action:'reset_timers')
    buttons << @reset

    setToolbarItems(buttons, animated: false)
  end

  def file_path
    NSHomeDirectory().stringByAppendingPathComponent("Documents/#{uuid}.json")
  end
end

