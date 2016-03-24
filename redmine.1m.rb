#!/usr/local/bin/ruby
# coding: utf-8

# <bitbar.title>Redmine</bitbar.title>
# <bitbar.version>v0.1.0</bitbar.version>
# <bitbar.author>hikouki</bitbar.author>
# <bitbar.author.github>hikouki</bitbar.author.github>
# <bitbar.desc>Show Redmine open ticket for mine repos</bitbar.desc>
# <bitbar.image>http://~</bitbar.image>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/hikouki</bitbar.abouturl>

require 'net/http'
require 'uri'
require 'json'

# a6140cbf6e84a0bAffb0cX49138fc5687310b518
token = ENV["REDMINE_ACCESS_TOKEN"] || ''
# https://redmine.xxxx.com
redmine_url = ENV["REDMINE_URL"] || ''

uri = URI.parse("#{redmine_url}/issues.json?key=#{token}&status_id=open&assigned_to_id=me")

https = Net::HTTP.new(uri.host, uri.port)
https.use_ssl = true
res = https.start {
  https.get(uri.request_uri)
}

if res.code == '200'
  result = JSON.parse(res.body, symbolize_names: true)

  projects = Hash.new { |h, k| h[k] = {issues_count: 0, issues: Hash.new { |h, k| h[k] = [] }} }
  issues = result[:issues]

  issues.each do | v |
    project_id   = v[:project][:id]
    project_name = v[:project][:name]
    status_id    = v[:status][:id]
    projects[project_id][:issues_count] += 1
    projects[project_id][:id] = project_id
    projects[project_id][:name] = project_name
    projects[project_id][:issues][status_id].push(v)
  end

  projects.sort

  puts "🐈 #{issues.count}"
  puts "---"
  puts "Redmine | color=black href=#{redmine_url}"
  puts "---"

  projects.each do | k, project |
      puts "#{project[:name]}: #{project[:issues_count]}"
      project[:issues].each do | k, status_issues |
        puts "[#{status_issues.first[:status][:name]}]"
        status_issues.each do | issue |
          prefix = status_issues.last == issue ? "└" : "├"
          puts "#{prefix} #{issue[:subject]} | color=black href=#{redmine_url}/issues/#{issue[:id]}"
        end
      end
    puts "---"
  end

else
  puts "error #{res.code} #{res.message}"
end
