#!/usr/bin/ruby
# usage: ./process.rb
# this processes the output obtained from lol.#!/usr/bin/env ruby -wKU

require 'csv'
require 'date'
require 'pp'

load 'Player.rb'


BEGIN {
  # this is called before the program is run
  puts "process is starting...\n"
}

END {
  # this is called at the end of the program
  puts "\nprocess is ending..."
}



baseDir = "/Users/davide/Desktop/AWS/download/"	# directory where actionlog.log is located
actionLogFileName = "actionlog.log"								# name of actionlog file

# if directory baseDir does not exist, abort
unless File.directory?(baseDir)
	puts "Directory does not exist, #{baseDir}"
	exit
end

# read the contents of actionlog.log, store data in the actionData struct
Struct.new("ActionData", :date, :epoch, :region, :csvFileName, :players)
actionList = Array.new

tmpFileName = baseDir + actionLogFileName	# full location of file
File.readlines(tmpFileName).each do |line|
	# if the line starts with '#', ignore it
	unless line[0] == '#'
		tmp = CSV.parse_line(line)
		actionList.push(Struct::ActionData.new(DateTime.parse(tmp[0]), tmp[1], tmp[2], tmp[3], tmp[4]))
	end
end

puts "I have loaded #{actionList.size} actions"



# go through the stats files and load all the player's data
playerList = Hash.new		# hash allows finding players, and adding stats, more easily
collisions = 0

#(0..actionList.size).each do |i|
[0,11,22,33,44,55,66,77,88,99,110,121,132,143,154,165,176,187,198,209].each do |i|	# for testing
	# go through every CSV file

	tmpFileName = baseDir + "logs/" + actionList[i].csvFileName
	File.readlines(tmpFileName).each do |line|
		# read data about all the players listed in the file
		unless line[0] == '#'
			cLine = CSV.parse_line(line)

			# date,id,rank,name,tier,lp,level,proTeam,win,loss
			tmpPlayer = Player.new(actionList[i].date, cLine[1], cLine[2], cLine[3], cLine[4], cLine[5], cLine[6], cLine[7], cLine[8], cLine[9])

			# check if the hash key already exist
			tmpHashKey = tmpPlayer.id		# this will be used to insert objects in the hash

			if playerList.has_key?(tmpHashKey)
				# if player does not have stats for the current date, add them, otherwise ignore
				# treat the variables in the Player class as arrays, it makes sense since they will be ordered by date
				playerRef = playerList[tmpHashKey]	# get reference to the player obj currently being worked on
				if tmpPlayer.date.last == playerRef.date.last
					collisions += 1
				else
					playerRef.pushValues(tmpPlayer)
				end
			else
				playerList[tmpHashKey] = tmpPlayer
			end

		end

	end

	puts "I have found #{playerList.size} players so far"

end

puts "I have found #{playerList.size} players, collisions: #{collisions}"



unless playerList.has_key?("summoner-37802452")
	puts "NOPE"
end

# puts playerList

tmpVar = playerList["summoner-37802452"]
# puts tmpVar.inspect
# puts tmpVar.date.size
# puts tmpVar.date
pp tmpVar
