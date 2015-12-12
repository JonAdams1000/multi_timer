class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    return true if RUBYMOTION_ENV == 'test'

    application.registerUserNotificationSettings(UIUserNotificationSettings.settingsForTypes(UIUserNotificationTypeSound | UIUserNotificationTypeAlert, categories: nil))

    @timer_sequence_list_controller = TimerSequenceListController.alloc.init
    @timer_sequence_list_controller.load
    @navigationController = MainViewController.alloc.init
    @navigationController.pushViewController(@timer_sequence_list_controller, animated: false)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = @navigationController
    @window.makeKeyAndVisible

    true
  end

  def applicationDidEnterBackground(application)
    active_timer_list_controller.save
    @timer_sequence_list_controller.save
    return unless active_timer_list_controller.running?
    @notifications = []
    @enter_background_time = NSDate.date.timeIntervalSince1970
    active_timer_list_controller.entering_background
    timers = active_timer_list_controller.timers
    grouped_times = timers.inject(Hash.new()) do |hash, timer|
      (hash[timer.time_till_finished] ||= []) << timer
      hash
    end
    grouped_times.each_pair do |remaining_time, grouped_timers|
      next if remaining_time <= 0
      finishes = (@enter_background_time * 1000) + remaining_time
      finish_date = NSDate.dateWithTimeIntervalSince1970(finishes.to_f / 1000.0)
      notification = create_notification(finish_date, grouped_timers)
      application.scheduleLocalNotification(notification)
      @notifications << notification
      puts "Notification scheduled!"
    end
  end

  def applicationWillEnterForeground(application)
    return unless @enter_background_time
    enter_foreground_time = NSDate.date
    interval = ((enter_foreground_time.timeIntervalSince1970 - @enter_background_time) * 1000).to_i
    already_fired = @notifications.select {|notification| notification.fireDate.earlierDate(enter_foreground_time) }
    fired_timer_uuids = already_fired.map {|notification| notification.userInfo["uuids"] }.flatten
    application.cancelAllLocalNotifications
    active_timer_list_controller.entering_foreground_after(interval, fired_timer_uuids)
  end

  def applicationWillTerminate(application)
    active_timer_list_controller.save
    @timer_sequence_list_controller.save
  end

  private
  def create_notification(trigger_date, timers)
    notification = UILocalNotification.alloc.init
    notification.fireDate = trigger_date
    notification.alertTitle = "Timer finished!"
    notification.alertBody = timers.size > 1 ? "#{timers.size} timers finished!" : "Timer finished!"
    notification.soundName = UILocalNotificationDefaultSoundName
    notification.userInfo = {"uuids" => timers.map(&:uuid)}
    notification
  end

  def active_timer_list_controller
    top_view_controller = @navigationController.topViewController
    if top_view_controller.is_a? TimerListController
      top_view_controller
    else
      NullTimerListController.new
    end
  end
end

# Used when there is no active timer list
class NullTimerListController
  def running?
    false
  end

  def save
  end
end

