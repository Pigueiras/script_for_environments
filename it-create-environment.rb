#!/usr/bin/ruby

require "highline/import"
require 'yaml'
require 'git'
require 'logger'

def create_a_branch(branch, path) 
	g = Git.open(path, :log => Logger.new(STDOUT))
	g.branch(branch).checkout
	g.push("origin", branch)
end

env = ask("What is the name of the new environment?") do |q| 
	q.validate = /.+/ 
	q.responses[:not_valid] = "Should not be blank"
end
#	
env.downcase!

email = ask("What is your email to send notifications?") do |q|
	q.default = "luis.oscar.pigueiras.areces@cern.ch"
end

if ask("Do you want to override a module?") { |q| q.default = "Y" } == "Y"
	mod = ask("What is the name of the module?") do |q|
		q.validate = /.+/ 
		q.responses[:not_valid] = "Should not be blank"
	end

end

if ask("Do you want to override a hostgroup") { |q| q.default = "Y" } == "Y"
	hostgroup = ask("What is the name of the hostgroup?") do |q|
		q.validate = /.+/ 
		q.responses[:not_valid] = "Should not be blank"
	end

end

if hostgroup.nil? and mod.nil?
	say("You need to set at least one hostgroup or module")
	exit(-1)
end

default_branch = ask("Default branch?") { |q| q.default = "master" } 

environment_path = ask("Environment path?") { |q| q.default = "/afs/cern.ch/user/l/lpigueir/private/repositories/new-punch-modules/it-puppet-environments/" }

overrides = {}
modules = {}
hostgroups = {}

unless mod.nil?
	modules[mod] = env
	overrides['modules'] = modules
end

unless hostgroup.nil?
	hostgroups[hostgroup] = env
	overrides['hostgroups'] = hostgroups
end



yaml_result = {}
yaml_result['default'] = default_branch
yaml_result['notifications'] = email
yaml_result['overrides'] = overrides

puts yaml_result


path_branch = ask("Path to create a new branch?") do |q| 
	q.gather = ""
end

say("Your new environment is: #{env}")
say("Your email is: #{email}")
say("The name of the module is: #{mod}") if mod
say("The name of the hostgroup is: #{hostgroup}")  if hostgroup
say("The default branch is: #{default_branch}") 

path_branch.each do |p|
	say("Creating a branch #{env} in #{p}")
	puts create_a_branch(env, p)
end

File.write(environment_path + "/" + env + ".yaml", yaml_result.to_yaml)
g = Git.open(environment_path, :log => Logger.new(STDOUT))
g.add(env + ".yaml")
g.commit("Added #{env} environment")
g.fetch
g.rebase("origin/master")
g.push("origin", "master")
