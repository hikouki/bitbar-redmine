#!/usr/local/bin/ruby
# coding: utf-8

# <bitbar.title>Redmine Show My Task</bitbar.title>
# <bitbar.version>v1.0.0</bitbar.version>
# <bitbar.author>hikouki</bitbar.author>
# <bitbar.author.github>hikouki</bitbar.author.github>
# <bitbar.desc>Show Redmine open ticket for mine</bitbar.desc>
# <bitbar.image>https://raw.githubusercontent.com/hikouki/bitbar-redmine/master/preview.png</bitbar.image>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/hikouki</bitbar.abouturl>

require 'net/http'
require 'uri'
require 'json'

# a6140cbf6e84a0bAffb0cX49138fc5687310b518
#   or
# launchctl setenv REDMINE_ACCESS_TOKEN a6140cbf6e84a0bAffb0cX49138fc5687310b518
TOKEN = ENV["REDMINE_ACCESS_TOKEN"] || ''
# https://redmine.xxxx.com
#   or
# launchctl setenv REDMINE_URL https://redmine.xxxx.com
REDMINE_URL = ENV["REDMINE_URL"] || ''

uri = URI.parse("#{REDMINE_URL}/issues.json?key=#{TOKEN}&limit=100&status_id=open&assigned_to_id=me")

begin
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do | http |
    http.get(uri.request_uri)
  end

  raise "error #{res.code} #{res.message}" if res.code != '200'

  result = JSON.parse(res.body, symbolize_names: true)
  issues = result[:issues]

  projects = Hash.new do | h, k |
    h[k] = {
      issues_count: 0,
      trackers: Hash.new do | h1, k1 |
        h1[k1] = {
          name: "tracker name.",
          statuses: Hash.new do | h2, k2 |
            h2[k2] = {
              name: "status name.",
              issues: []
            }
          end
        }
      end
    }
  end

  issues.each do | v |
    project_id   = v[:project][:id]
    status_id    = v[:status][:id]
    tracker_id   = v[:tracker][:id]
    projects[project_id][:issues_count] += 1
    projects[project_id][:id] = project_id
    projects[project_id][:name] = v[:project][:name]
    projects[project_id][:trackers][tracker_id][:name] = v[:tracker][:name]
    projects[project_id][:trackers][tracker_id][:statuses][status_id][:name] = v[:status][:name]
    projects[project_id][:trackers][tracker_id][:statuses][status_id][:issues].push(v)
  end

  issue_total_count = result[:total_count] > 99 ? '99+' : result[:total_count]
  puts issues.empty? ? "✦ | color=#7d7d7d" : "✦ #{issue_total_count}"
  puts "---"
  puts "Redmine | color=black href=#{REDMINE_URL}"
  puts "---"

  projects.each do | _, project |
    puts "#{project[:name]}: #{project[:issues_count]} | size=11"
    project[:trackers].each do | _, tracker |
      puts "➠ #{tracker[:name]} | color=#33BFDB size=11"
      tracker[:statuses].each do | _, status |
        puts "[#{status[:name]}] | color=#58BE89 size=11"
        status[:issues].each do | issue |
          prefix = status[:issues].last == issue ? "└" : "├"
          puts "#{prefix} ##{issue[:id]} #{issue[:subject]} | color=black href=#{REDMINE_URL}/issues/#{issue[:id]} size=11"
        end
      end
    end
    puts "---"
  end
rescue => e
  puts "✦ ! | color=#ECB935"
  puts "---"
  puts "Exception: #{$!}"
  puts e.backtrace
end
