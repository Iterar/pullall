require 'rubygems'
require 'oj'

module Actions

  STORAGE = "#{ENV['HOME']}/.pullall"

  def get_real_paths(paths)
    paths.collect! do |path|
      if File.exists?(path)
        File.realpath(path)
      else
        Trollop::die "The path #{path} doesn't exist"
      end  
    end
    paths
  end

  def list_groups
    groups = load_all
    puts "\n"
    groups.each do |group, paths|
      puts "#{group} - #{paths}"
      puts "\n"
    end
  end

  def save_all(groups)
    json = Oj.dump(groups)
    Oj.to_file(STORAGE, json)
  end

  def save_paths(*paths, group)
    groups = load_all
    
    # Use real path to allow the use of .(current directory) as an argument
    if groups.has_key?(group)
      paths.each do |path|
        if groups[group].include?(path)
          Trollop::die "Path #{path} already exists in group #{group}"
        end
      end
      groups[group].push(*paths)
    else
      groups[group] = [*paths]
    end
    save_all(groups)
    msg = paths.empty? ? "Group successfully created" : "Path successfully saved"
    puts msg
  end

  def load_paths(group)
    groups = load_all
    if groups.has_key?(group)
      groups[group]
    else
      Trollop::die "Group #{group} doesn't exist"
    end
  end

  def load_all
    begin
      if not File.exists?(STORAGE)
        # Initiate file with valid json
        File.new(STORAGE, "w")
        Oj.to_file(STORAGE, Oj.dump({}))
      end
      json = Oj.load_file(STORAGE)
      Oj.load(json)
    rescue
      Trollop::die "~/.pullall has invalid JSON. If you changed that file then 
                    fix it so that it has valid json. If this problem persists
                    remove the file (rm ~/.pullall)."
    end
  end

  def remove_group(group)
    groups = load_all
    deleted = groups.delete(group)
    msg = deleted ? "Group successfully deleted" : "Group doesn't exist"
    save_all(groups)
    puts msg
  end

  def remove_paths(*paths, group)
    groups = load_all

    if groups.has_key?(group)
      existent_paths = groups[group]

      # First check if all the paths belong to the given group
      paths.each do |path|
        if existent_paths.include?(path)
          existent_paths.delete(path)  
        else
          Trollop::die "Given path #{path} doesn't belong to group #{group}. Changes not saved."
        end
      end
      save_all(groups)
      puts "Paths successfully removed from group #{group}"
    else
      Trollop::die "Group #{group} doesn't exist"
    end
  end

  def pull(group)
    paths = load_paths(group)
    paths.each do |path|
      puts "Pulling from #{path}:"
      %x(git --git-dir #{path}/.git pull origin master)
      puts "\n"
    end
  end
end