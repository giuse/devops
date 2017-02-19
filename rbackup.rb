#!/usr/bin/env ruby
# rbackup - remote backup utility - version 3.0 - October 2016
# Copyright © 2011-2016 Giuseppe Cuccu - all rights reserved
# This script is provided AS USED and under constant updating - NO WARRANTY

class RBackup
	class << self
		attr_reader :config_file, :starting_time, :destinations, :destination,
			:server_command

		def intro
			# @config_file = ENV['HOME']+'/.rbackup.conf'
			@config_file = 'conf_test.rb'
			@starting_time = Time.now
		end

		def load_config_file
			unless File.file? config_file
		    puts "Config file #{config_file} not found - creating"
		    write_conf_file
		    puts "Config file #{config_file} created - please customize it and try again"
		    exit 1
			end
			eval File.read config_file # HACK: refactor better config loader
		end

		def set_dest
			destinations.each do |dest|
				if test_destination dest
					puts "Destination found: `#{dest}`"
					set_destination dest
					break
				else
					puts "Skipping destination `#{dest}`: unreachable"
				end
			end
			abort "Couldn't set destination." if server_command.nil?
		end

		def test_destination server:nil, port:22, path:nil
			if server.nil?
				# check local folder
				File.directory? path.to_s
			else
				# test server connection
				# TODO: implement
				# `nc -zw 10 #{server} #{port} 2> /dev/null && ssh #{server} -p #{port} test -d "#{path}"`
				true
			end
		end

		def set_destination server:nil, port:22, path:nil
			if server.nil?
				# local destination
				@server_command = []
				@destination = dest
			else
				# test server connection
				# TODO: implement
				# `nc -zw 10 #{server} #{port} 2> /dev/null` && system(*server_command, "test", "-d", %Q["#{path}"])
				true
			end
		end

		def write_conf_file

		end

		def main
			intro
			load_config_file
			set_dest
			puts starting_time
		end

	end
end

RBackup::main

