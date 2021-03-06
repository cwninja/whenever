class CommandLine
  START_MARKER = "### BEGIN whenever generated crontab ###"
  END_MARKER =   "### END   whenever generated crontab ###"

  attr_reader :options

  def start_marker
    "### BEGIN #{@marker} ###"
  end

  def end_marker
    "### END   #{@marker} ###"
  end

  def initialize(options = {})
    @options = options
    @marker = options[:marker] || "whenever generated crontab"
  end

  def write!
    cron_output = Whenever.cron(options)
    write_crontab(cron_output)
  end

  def update!
    before, after = strip_whenever_crontab(read_crontab)
    whenever_cron = Whenever.cron(options)
    write_crontab((before + [start_marker, whenever_cron, end_marker] + after).compact.join("\n"))
  end

  private
  def strip_whenever_crontab(existing_crontab)
    return [], [] if existing_crontab.nil? or existing_crontab == ""
    lines = existing_crontab.split("\n")
    if start = lines.index(start_marker)
      if finish = lines.index(end_marker)
        return lines[0...start], lines[(finish + 1)..-1]
      else
        warn "[fail] could not find END marker in existing crontab"
        exit(1)
      end
    else
      return lines, []
    end
  end

  def read_crontab
    command = ['crontab']
    command << "-u #{options[:user]}" if options[:user]
    command << "-l"

    IO.popen(command.join(' ')) do |io|
      return io.read
    end
  end

  def write_crontab(data)
    tmp_cron_file = Tempfile.new('whenever_tmp_cron').path
    File.open(tmp_cron_file, File::WRONLY | File::APPEND) do |file|
      file.puts data
    end

    command = ['crontab']
    command << "-u #{options[:user]}" if options[:user]
    command << tmp_cron_file

    if system(command.join(' '))
      puts "[write] crontab file updated"
      exit
    else
      warn "[fail] couldn't write crontab"
      exit(1)
    end
  end

end
