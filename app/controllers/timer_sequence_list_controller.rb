
class TimerSequenceListController < UITableViewController
  FILENAME = "timer_sequence_list.json"

  def init
    super.tap do
      @timer_sequences = []
    end
  end

  def viewDidLoad
    super
    tableView.dataSource = self
    tableView.delegate = self
    tableView.allowsMultipleSelectionDuringEditing = false

    @create = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemAdd, target:self, action:'create_sequence')
    navigationItem.rightBarButtonItem = @create
  end

  def save
    sequences = []
    @timer_sequences.each do |view|
      sequences << {uuid: view.controller.uuid, name: view.controller.name}
    end
    string = BW::JSON.generate(sequences)
    NSFileManager.defaultManager.createFileAtPath(file_path, contents:string.dataUsingEncoding(NSUTF8StringEncoding), attributes:nil)
  end

  def load
    return unless NSFileManager.defaultManager.fileExistsAtPath(file_path)
    content = NSString.alloc.initWithData(NSFileManager.defaultManager.contentsAtPath(file_path), encoding:NSUTF8StringEncoding)
    hashed_sequences = BW::JSON.parse(content)
    hashed_sequences.each do |sequence|
      puts sequence.inspect
      @timer_sequences << TimerSequenceCellView.alloc.init(sequence['uuid'], sequence['name'])
      @timer_sequences.last.load
    end
    reload_table
  end

  def reload_table
    view.reloadData
  end

  # Data source methods
  def tableView(tableView, cellForRowAtIndexPath:index)
    @timer_sequences[index.row]
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @timer_sequences.size
  end

  def tableView(tableView, canEditRowAtIndexPath:index)
    true
  end

  def tableView(tableView, commitEditingStyle:style, forRowAtIndexPath:index)
    if (style == UITableViewCellEditingStyleDelete)
      sequence = @timer_sequences[index.row]
      if sequence.controller.running?
        sequence.controller.stop
      end
      sequence.controller.delete # Removes the saved file
      @timer_sequences.delete(sequence)
      tableView.deleteRowsAtIndexPaths([index], withRowAnimation:UITableViewRowAnimationAutomatic)
      save
    end
  end
  # End of data source methods

  # Delegate methods
  def tableView(tableView, didSelectRowAtIndexPath:index)
    sequence = @timer_sequences[index.row]
    navigationController.pushViewController(sequence.controller, animated: true)
  end
  # End of delegate methods

  private
  def create_sequence
    @timer_sequences << TimerSequenceCellView.alloc.init(NSUUID.UUID.UUIDString, "New Sequence")
    @timer_sequences.last.save
    save
    reload_table
  end

  def file_path
    NSHomeDirectory().stringByAppendingPathComponent("Documents/#{FILENAME}")
  end
end

