#!/usr/bin/ruby
# usage: ./process.rb
# this processes the output obtained from lol.rb

require 'csv'
require 'date'
require 'pp'
require 'gnuplot'

load 'Player.rb'




BEGIN {
  # this is called before the program is run
  puts "process is starting...\n"
}

END {
  # this is called at the end of the program
  puts "\nprocess is ending..."
}



class ProcessLOL

	def initialize(actionLogDir, actionLogName, statsDir)
		@actionLogDir = actionLogDir	# directory where actionlog.log is located
		@statsDir = statsDir	# directory where raw stats are stored
		@actionLogFileName = actionLogName								# name of actionlog file
		@procDataDir = actionLogDir + "processed_data/"

		# if directory actionLogDir does not exist, send a nil value so that parent object can be aware of this
		unless File.directory?(actionLogDir)
			puts "Directory does not exist, #{actionLogDir}"
			return nil
		end

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

		@actionList = Array.new		# maintain list of info on actions done, from action log, makes it easier to get stats
		@playerList = Array.new(REGIONS_NUM){Hash.new}		# hash makes it easier to add players and add stats per region
		@collisions = 0		# times any player is found more than once in the same stats file (same date)

		readActionLog		# read the action log file, populate actionList

	end

	def readPlayerData(statsFile, regionID, actionIndex)
		# read player stats from a stats file
		# puts "#{statsFile}, #{regionID}"
		File.readlines(statsFile).each do |line|
			# read data about all the players listed in the file
			unless line[0] == '#'
				cLine = CSV.parse_line(line)

				# epoch,id,rank,name,tier,lp,level,proTeam,win,loss
				tmpPlayer = Player.new(actionList[actionIndex].epoch, cLine[1], cLine[2], cLine[3], cLine[4], cLine[5].to_i, cLine[6].to_i, cLine[7], cLine[8].to_i, cLine[9].to_i, actionList[actionIndex].region, regionID)

				# check if the hash key already exist
				tmpHashKey = tmpPlayer.id		# this will be used to insert objects in the hash

				if playerList[regionID].has_key?(tmpHashKey)
					# if player does not have stats for the current epoch, add them, otherwise ignore
					# treat the variables in the Player class as arrays, it makes sense since they will be ordered by epoch
					playerRef = playerList[regionID][tmpHashKey]	# get reference to the player obj currently being worked on
					if tmpPlayer.epoch.last == playerRef.epoch.last
						@collisions += 1
					else
						playerRef.pushValues(tmpPlayer)
					end

				else
					playerList[regionID][tmpHashKey] = tmpPlayer
				end
			end
		end

		puts "regionID: #{regionID} - I have found #{playerList[regionID].size} unique players in #{actionList[actionIndex].region}"

	end

	def loadAllPlayerData()
		# calls readPlayerData() for every entry in actionList
		# (0...actionList.size).each do |i|
		[0,11,22,33,44,55,66,77,88,99,110,121,132,143,154,165,176,187,198,209,220].each do |i|	# for testing
			# go through every CSV file, put players of each region in the appropriate regionID
			tmpStatsFile = statsDir + actionList[i].csvFileName
			regionID = REGIONS.index(actionList[i].region)
			readPlayerData(tmpStatsFile, regionID, i)
		end

	end

	def printUniquePlayerNum()
		(0...REGIONS_NUM).each do |i|
			puts "I have found #{playerList[i].size} unique players, in #{REGIONS[i]}"
		end
	end


	def savePlayerGamesStats(fileLocation, num, regionID)
		# save stats of games of players of a certain region, (wins, losses, total games)
		# use num to specify how many players, from the top ranked player, i.e. num=10 will take the 10 highest ranked players
		# if a single player is given, num should be 1
		if num == 0	# bad input parameter
			return	# TODO: raise exception?
		end

		playerData = playerList[regionID].values
		playerData = playerData.sort_by!{|player| player.rank}	# hash is not ordered, order players by rank
		playerData = playerData[0,num]	# take the top num players
		samples = playerData[0].win.size
		# puts "players: #{playerData.size}\tsamples: #{samples}"

		fileOut = File.open(fileLocation, "w")

		# put a header in the file and save the IDs of the players in case this will be plotted in the future
		fileOut << "# each player has 3 columns: win, loss, total games\n"
		fileOut << "# the two left most columns are the date in human readable and epoch timestamp format\n"
		fileOut << "# region: #{playerData[0].region}, players: #{playerData.size}\n"
		fileOut << "# playerIDs: "
		(0...playerData.size).each do |i|
			fileOut << playerData[i].id << ","
		end
		fileOut << "\n"


		# save data to file
		(0...samples).each do |pIndex|	# how many times the data was collected
			# for players of the same region, stats are taken at the same time
			tmpEpoch = playerData[0].epoch[pIndex].to_s
			tmpDateFromEpoch = DateTime.strptime(tmpEpoch,'%Q').to_s
			fileOut << tmpDateFromEpoch << "," << tmpEpoch << ","

			(0...playerData.size).each do |i|		# for each player
				fileOut << playerData[i].win[pIndex] << ","
				fileOut << playerData[i].loss[pIndex] << ","
				fileOut << playerData[i].totalGamesPlayed[pIndex] << ","
			end

			fileOut << "\n"
		end

		fileOut.close

	end

	def plotPlayerGamesStats(plotFile, num, regionID)
		# save stats of games of players of a certain region, (wins, losses, total games)
		# use num to specify how many players, from the top ranked player, i.e. num=10 will take the 10 highest ranked players
		# if a single player is given, num should be 1
		if num == 0	# bad input parameter
			return	# TODO: raise exception?
		end

		playerData = playerList[regionID].values
		playerData = playerData.sort_by!{|player| player.rank}	# hash is not ordered, order players by rank
		playerData = playerData[0,num]	# take the top num players
		samples = playerData[0].win.size
		puts "players: #{playerData.size}\tsamples: #{samples}"
		puts playerData[0].win[0].class

		# plot the playerData array
		Gnuplot.open do |gp|
			Gnuplot::Plot.new(gp) do |plot|
				# set general gnuplot things
			  plot.terminal("png size 1280,720 transparent")
				plot.title("PLAYER WINS")
			  plot.output(plotFile)

			  # stuff for x-axis
				plot.xlabel("Day no.")
				plot.grid("xtics")
				plot.xrange("[:]")

				# stuff for y-axis
			  plot.ylabel("Total Wins")
				plot.grid("ytics")
				plot.yrange("[:]")

			  # plot.data << Gnuplot::DataSet.new([dataX[0], dataY[0]]) do |ds|
				# # plot.data << Gnuplot::DataSet.new([dataArray.map{|a| a[0]}, dataArray.map{|a| a[1]}]) do |ds|
				# 	ds.title = "penis"
			  #   ds.with = "linespoints"
			  #   ds.linewidth = 4
			  # end

				# plot.data expects to be given an array
				plot.data = Array.new(playerData.size) { |i|
					puts playerData[i].win

					Gnuplot::DataSet.new(playerData[i].win) { |ds|
						ds.with = "lines"
						ds.title = playerData[i].id
						ds.linewidth = 2
					}

					# Gnuplot::DataSet.new([tmpDateFromEpoch, playerData[1].totalGamesPlayed[i]]) { |ds|
					# 	ds.with = "lines"
					# 	ds.title = "data " + i.to_s
					# 	ds.linewidth = 2
					# }

				}


			end
		end


	end



	# private
	def readActionLog()
		# read the contents of actionlog.log, store data in the actionData struct
		Struct.new("ActionData", :date, :epoch, :region, :csvFileName, :players)

		tmpFileName = actionLogDir + actionLogFileName	# full location of file
		File.readlines(tmpFileName).each do |line|
			# if the line starts with '#', ignore it
			unless line[0] == '#'
				tmp = CSV.parse_line(line)
				actionList.push(Struct::ActionData.new(DateTime.parse(tmp[0]), tmp[1], tmp[2], tmp[3], tmp[4]))
			end

			# if actionList.size > 100		# for testing
			# 	break
			# end
		end

		puts "I have loaded #{actionList.size} actions to process"
	end


	# accessors
	attr_accessor :actionLogDir, :statsDir, :actionLogFileName, :procDataDir
	attr_reader :actionList, :playerList
	attr_writer :collisions


end





str1 = "/Users/davide/Desktop/Code/RUBY/LoLLeaderboardCrawler/"	# actionLogDir
str2 = "actionlog.log"				# actionLogName
str3 = str1 + "logs/"					# statsDir
str4 = str1 + "processed_data/"		# procDataDir


testObj = ProcessLOL.new(str1, str2, str3)

# tmpStatsFile = str3 + testObj.actionList[0].csvFileName
# regionID = REGIONS.index(testObj.actionList[0].region)
# testObj.readPlayerData(tmpStatsFile, 0, regionID)
testObj.loadAllPlayerData
testObj.printUniquePlayerNum

testObj.savePlayerGamesStats(str4 + "games_euw.dat", 3, 0)
testObj.plotPlayerGamesStats(str4 + "games_euw.png", 10, 0)

exit





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
