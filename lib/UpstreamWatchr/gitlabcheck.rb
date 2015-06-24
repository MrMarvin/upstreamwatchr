require 'gitlab'

module UpstreamWatchr
  class GitLabWatchr
    attr_reader :origin_url, :origin_project, :comparator

    def initialize(origin_url, branch = 'master')
      @origin_url = origin_url
      @branch = branch
      @comparator = GitRemotes.new(@origin_url, upstream_url)
    end

    def origin_project
      @origin_project ||= Gitlab.projects(:per_page => 10000).find {|p| p.ssh_url_to_repo == @origin_url || p.http_url_to_repo == @origin_url || p.web_url == @origin_url }
    end

    def upstream_url
      @upstream_url ||= origin_project.description.match(/^Upstream: (\S*)$/)[1]
    end

    def create_fork
      puts "Forking #{origin_project.name}..."
      Gitlab.create_fork(@origin_project.id)
    rescue Gitlab::Error::Conflict
      puts "Fork of #{origin_project.name} already exists."
    end

    def fork
      @fork ||= (Gitlab.projects(:per_page => 10000).find {|p| p.forked_from_project && p.forked_from_project.id == @origin_project.id } || create_fork)
    end

    def create_merge_request
      @comparator.push_to_my_fork(fork.ssh_url_to_repo)

      puts "Creating merge request on #{origin_project.name}..."
      Gitlab.create_merge_request(fork.id,
        'UpstreamWatcher detected new upstream changes!',
        :source_branch => @branch,
        :target_branch => @branch,
        :target_project_id => origin_project.id
        )
    rescue Gitlab::Error::Conflict
      puts "Merge request seems to be already there. Good. Previous MR updated with even more upstream changes!"
    end

    def issue_title
      "UpstreamWatchr: #{@comparator.upstream_ahead} change(s) to fetch from your upstream project!"
    end

    def issue_description
      "UpstreamWatchr noted that your branch '#{@branch}' is #{@comparator.upstream_ahead} commits behind `#{upstream_url}`'s #{@branch}.

  Whenenver you feel confident pulling the upstream changes onto your branch, you can use these git commands:

  ```
  git checkout #{@branch}
  git pull #{upstream_url} #{@branch}
  git push origin #{@branch}
  ```


  Sincerly, UpstreamWatchr"
    end

    def issue
      @issue ||= find_issue || create_issue
    end

    def find_issue
       Gitlab.issues(@origin_project.id, :per_page => 1000).find {|i| i.state != 'closed' && i.author.id == Gitlab.user.id && i.title =~ /^UpstreamWatchr:/}
    end

    def create_issue
      puts "Warn: Creating new issue '#{issue_title}'"
      Gitlab.create_issue(@origin_project.id,
        issue_title,
        {:description => issue_description}
      )
    end

    def update_issue
      puts "Debug: Updating issue '#{issue_title}'" if ENV['DEBUG']
      Gitlab.edit_issue(@origin_project.id, issue.id, :title => issue_title)
      Gitlab.create_issue_note(@origin_project.id, issue.id, issue_title)
    end

    def grumble_in_issue
      changes_in_title = issue.title.match(/(\d+)/)[1].to_i
      puts "Debug: Issue states '#{changes_in_title} changes'" if ENV['DEBUG']
      unless changes_in_title == @comparator.upstream_ahead
        puts "Warn: Going to update issue to '#{issue_title}'"
        update_issue
      end
    end

  end
end
