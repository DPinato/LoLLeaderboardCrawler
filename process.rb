#!/usr/bin/ruby
# usage: ./process.rb
# this processes the output obtained from lol.rb

require 'csv'
require 'date'
require 'pp'

load 'Player.rb'

REGIONS = ["euw", "www", "jp", "na", "eune", "oce", "br", "las", "lan", "ru", "tr"]		# initials of the regions
REGIONS_NUM = REGIONS.size		# number of regions being monitored


BEGIN {
  # this is called before the program is run
  puts "process is starting...\n"
}

END {
  # this is called at the end of the program
  puts "\nprocess is ending..."
}



def savePlayerGamesStats(fileLocation, num, playerData)
	# save stats of num players in fileLocation as CSV
	# playerData could be an array of Player objects, or a single Player object
	# if a single player is given, num should be 1
	if num == 0	# bad input parameter
		return	# TODO: raise exception?
	end

	# this way is a little janky, but it works since the rest of the code thinks that it was given an array
	# puts playerData.class
	# puts playerData.win
	# puts playerData.loss
	# puts playerData.totalGamesPlayed
	if playerData.is_a?(Player)
		tmpPlayerData = Array.new
		tmpPlayerData[0] = playerData
	elsif playerData.is_a?(Array)
		tmpPlayerData = playerData
	else	# TODO: raise exception
		puts "savePlayerGamesStats() does not understand anything but Array or Player objects"
		return
	end


	tmpFileStr = fileLocation + "games_" + tmpPlayerData[0].region + ".dat"
	fileOut = File.open(tmpFileStr, "w")

	# put a header in the file
	fileOut << "# each player has 3 columns: win, loss, total games\n"
	fileOut << "# the two left most columns are the date in human readable and epoch timestamp format\n"
	fileOut << "# region: #{tmpPlayerData[0].region}, players: #{num}\n"

	samples = tmpPlayerData[0].totalGamesPlayed.size
	puts "samples: #{samples}"

	(0...samples).each do |pIndex|
		(0...num).each do |i|
			tmpEpoch = tmpPlayerData[i].epoch[pIndex].to_s
			fileOut << DateTime.strptime(tmpEpoch,'%Q').to_s << ","
			fileOut << tmpEpoch << ","

			fileOut << tmpPlayerData[i].win[pIndex] << ","
			fileOut << tmpPlayerData[i].loss[pIndex] << ","
			fileOut << tmpPlayerData[i].totalGamesPlayed[pIndex] << ","
			fileOut << "\n"

		end
	end

	fileOut.close

end



baseDir = "/Users/davide/Desktop/Code/RUBY/LoLLeaderboardCrawler/"	# directory where actionlog.log is located
statsDir = baseDir + "logs/"
procDataDir = baseDir + "processed_data/"
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

	if actionList.size > 20		# for testing
		break
	end
end

puts "I have loaded #{actionList.size} actions to process"



# go through the stats files and load all the player's data
playerList = Array.new(REGIONS_NUM){Hash.new}		# hash allows finding players, and adding stats, more easily
collisions = 0

(0...actionList.size).each do |i|
# [0,11,22,33,44,55,66,77,88,99,110,121,132,143,154,165,176,187,198,209].each do |i|	# for testing
	# go through every CSV file, put players of each region in the appropriate regionID
	regionID = REGIONS.index(actionList[i].region)

	tmpFileName = statsDir + actionList[i].csvFileName
	File.readlines(tmpFileName).each do |line|
		# read data about all the players listed in the file
		unless line[0] == '#'
			cLine = CSV.parse_line(line)

			# epoch,id,rank,name,tier,lp,level,proTeam,win,loss
			tmpPlayer = Player.new(actionList[i].epoch, cLine[1], cLine[2], cLine[3], cLine[4], cLine[5].to_i, cLine[6].to_i, cLine[7], cLine[8].to_i, cLine[9].to_i, actionList[i].region, regionID)

			# check if the hash key already exist
			tmpHashKey = tmpPlayer.id		# this will be used to insert objects in the hash

			if playerList[regionID].has_key?(tmpHashKey)
				# if player does not have stats for the current epoch, add them, otherwise ignore
				# treat the variables in the Player class as arrays, it makes sense since they will be ordered by epoch
				playerRef = playerList[regionID][tmpHashKey]	# get reference to the player obj currently being worked on
				if tmpPlayer.epoch.last == playerRef.epoch.last
					collisions += 1
				else
					playerRef.pushValues(tmpPlayer)
				end
			else
				playerList[regionID][tmpHashKey] = tmpPlayer
			end

		end

	end

	puts "#{i} - I have found #{playerList[regionID].size} unique players in #{actionList[i].region} so far"

end

puts "\n\n"
(0...REGIONS_NUM).each do |i|
	puts "I have found #{playerList[i].size} unique players, in #{REGIONS[i]}"
end


puts "collisions: #{collisions}"






# put files with processed data in the "processed_data" directory, create it if it does not exist
unless Dir.exist?(procDataDir)
	begin
		FileUtils.mkpath(procDataDir)	# if needed, this will create every single directory that does not exist yet,
																	# so that the path will be created

		rescue SystemCallError
			puts "Could not create directory for processed data, #{procDataDir}, exiting..."
			exit
	end
end


# save a bunch of top 10 player stats as a test
playerArray = playerList[0].to_a
playerArray.sort_by!{}
playerArray = playerArray[0,10]
puts playerArray.size

# savePlayerGamesStats(procDataDir, 1, playerArray)





# unless playerList[0].has_key?("summoner-37802452")
# 	puts "NOPE"
# end

# puts playerList

# tmpVar = playerList[0]["summoner-37802452"]
# puts tmpVar.inspect
# puts tmpVar.date.size
# puts tmpVar.date
# pp tmpVar
