require 'rugged'
require 'tmpdir'

module UpstreamWatchr
  class GitRemotes

    def initialize(origin, upstream, main_branch = 'master')
      @origin = origin
      @upstream = upstream
      @main_branch = main_branch

      begin
        @repo = Rugged::Repository.clone_at(@origin, clone_path, {:bare => true, :credentials => ssh_agent})
        puts "Debug: cloned #{@origin} to #{clone_path}" if ENV['DEBUG']
      rescue Rugged::InvalidError
        puts "Debug: didn't clone (#{@origin} to #{clone_path}), local repo already there." if ENV['DEBUG']
        @repo = Rugged::Repository.new(clone_path)
        @repo.remotes['origin'].fetch({:credentials => ssh_agent})
        @repo.remotes['origin'].save
        puts "Debug: fetched 'origin' from #{origin}" if ENV['DEBUG']
      end

      @repo.remotes.create('upstream', @upstream) unless @repo.remotes['upstream']
      fail "Can not read from upstream. Something seems off with remote #{@upstream}" unless @repo.remotes['upstream'].check_connection(:fetch, {:credentials => ssh_agent})
      @repo.remotes['upstream'].fetch({:credentials => ssh_agent})
      @repo.remotes['upstream'].save
      puts "Debug: fetched 'upstream' from #{@upstream}" if ENV['DEBUG']
    end

    def ssh_agent
      lambda { |_, username, _| Rugged::Credentials::SshKeyFromAgent.new(username: username)}
    end

    def clone_path
      File.join(Dir.tmpdir, @origin.split('/').last)
    end

    def push_to_my_fork(my_fork_url, branch = nil)
      branch ||= @main_branch
      @repo.remotes.create('my_fork', my_fork_url) unless @repo.remotes['my_fork']

      @repo.reset("upstream/#{branch}", :soft)
      @repo.remotes["my_fork"].push("refs/heads/#{branch}", {:credentials => ssh_agent})
    end

    def diff(branch = nil)
      branch ||= @main_branch
      origin_target = @repo.references["refs/remotes/origin/#{branch}"].target
      puts "Debug: origin has its #{branch} at #{origin_target}" if ENV['DEBUG']
      upstream_target = @repo.references["refs/remotes/upstream/#{branch}"].target
      puts "Debug: upstream has its #{branch} at #{upstream_target}" if ENV['DEBUG']
      @repo.diff(origin_target, upstream_target)
    end

    def ahead_behind(branch = nil)
      branch ||= @main_branch
      @repo.ahead_behind(@repo.references["refs/remotes/origin/#{branch}"].target, @repo.references["refs/remotes/upstream/#{branch}"].target)
    end

    def upstream_ahead
      ahead_behind[1]
    end

    def upstream_behind
      ahead_behind[0]
    end

    def trees(branch = nil)
      branch ||= @main_branch
      [@repo.references["refs/remotes/origin/#{branch}"].target.tree, @repo.references["refs/remotes/upstream/#{branch}"].target.tree]
    end

    def origin_tree_size(branch = nil)
      branch ||= @main_branch
      trees(branch)[0].count
    end

    def upstream_tree_size(branch = nil)
      branch ||= @main_branch
      trees(branch)[1].count
    end

    def tree_size_diff(branch = nil)
      branch ||= @main_branch
      upstream_tree_size(branch) - origin_tree_size(branch)
    end

    def has_changes?
      ahead_behind != [0,0]
    end

    def to_s(branch = nil)
      branch ||= @main_branch
      a_b = ahead_behind(branch)
      if a_b == [0,0]
        "origin/#{branch} is up-to-date with 'upstream/#{branch}'"
      else
        "upstream/#{branch} is #{upstream_ahead} ahead and #{upstream_behind} behind 'origin/#{branch}'"
      end
    end

  end
end