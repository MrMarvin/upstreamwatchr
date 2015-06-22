# UpstreamWatchr
makes it easy to keep track of changes in the upstream repositories of your forks by comparing two git remotes and creating an issue on your fork if it is out of sync.


Currently only GitLab is supported (api wise). This means that it will fail (horribly) if you are using something else for your repos. It also has some requirements on your projects, such as that its needs a hyperlink in your projects `description` to find the upstream repository. Also your project should allow upstreamwatchr's user to read the code and create issues. If your project is not setup this way, UpstreamWatchr will fail, again, horribly.

## Installation

Add this line to your application's Gemfile:

    gem 'upstreamwatchr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install upstreamwatchr

## Usage

Set `ENV['GITLAB_API_ENDPOINT']` and `ENV['GITLAB_API_PRIVATE_TOKEN']` and use the "binary":
```
# Check a single project
GITLAB_API_ENDPOINT=https://git.acme.com/ GITLAB_API_PRIVATE_TOKEN=abcdefg123456 upstreamwatchr git@githost.acme.com:/path/repo.git
```
```
# Check all available projects
GITLAB_API_ENDPOINT=https://git.acme.com/ GITLAB_API_PRIVATE_TOKEN=abcdefg123456 upstreamwatchr"
```
