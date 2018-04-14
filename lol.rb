#!/usr/bin/ruby
# usage: ./RCrawler.rb <config_file>
require 'open-uri'
require 'date'
require 'csv'


BEGIN {
  # this is called before the program is run
  puts "lol is starting...\n"
}

END {
  # this is called at the end of the program
  puts "\nlol is ending..."
}


class Player

  def initialize(id=-1)
    @objId = id   # useful when using multiple threads
  end

	attr_accessor :id				# summoner ID (in case name changes)
	attr_accessor :rank			# rank in the leaderboards
  attr_accessor :name			# name of the player
	attr_accessor :tier			# tier of player
	attr_accessor :lp				# LP
  attr_accessor :level		# level of account
	attr_accessor :proTeam	# name of professional team, if player is part of one
	attr_accessor :win			# number of matches won
	attr_accessor :loss			# number of matches lost

end


# the first five players are in special classes
# use these to locate the data from each player
playerDivStartTop5 = "<li class=\"ranking-highest__item"
playerDivEndTop5 = "</li>"
playerDivStart = "<tr class=\"ranking-table__row"
playerDivEnd = "</tr>"

playersPerPage = 100
playersToTrack = 1000
playersFound = 0
playersRawData = Array.new

totalPages = (playersToTrack / playersPerPage.to_f).ceil	# total pages to download
lastPagePlayers = playersToTrack % playersPerPage	# players in the last page

puts "totalPages: " + totalPages.to_s
puts "lastPagePlayers: " + lastPagePlayers.to_s

region = "euw"
currPageNum = 1	# start from page 1


while currPageNum < (totalPages+1)	# because currPageNum starts from 1
	# go through all the pages to donwload all the players selected
	counter = 0
	length = 0

	url = "http://" + region + ".op.gg/ranking/ladder/page="	+ currPageNum.to_s	# build URL
	queryResponse = open(url).read
	puts "currPageNum: " + currPageNum.to_s + "\t" + queryResponse.length.to_s
	puts url


	# players start at the line beginning with playerDivStart
	while counter < queryResponse.length

		if playersFound < 5
			counter = queryResponse.index(playerDivStartTop5, counter)	# find beginning of player info
			length =  queryResponse.index(playerDivEndTop5, counter) - counter	# length of the raw data for the player
			length += playerDivEndTop5.length		# include the closing </li> HTML tag
		else
			# this gets executed for any player below rank 5 (rank > 5)
			counter = queryResponse.index(playerDivStart, counter)	# find beginning of player info
			if counter == nil
				puts "DONE"
				break
			end

			length =  queryResponse.index(playerDivEnd, counter) - counter	# length of the raw data for the player
			length += playerDivEnd.length		# include the closing </li> HTML tag
		end

		playersRawData[playersFound] = queryResponse[counter, length]
		#puts playerRawData[playersFound]

		playersFound += 1
	  counter += 1	# this loop should end long before the whole page is analysed

		if playersFound >= playersToTrack
			break
		end

	end

	currPageNum += 1

end

puts "playersFound: " + playersFound.to_s
puts "playersRawData size: " + playersRawData.size.to_s


# save raw data to file
rawFileDir = "/home/davide/Desktop/LoLLeaderboardCrawler/raw_" + DateTime.now.strftime('%Q').to_s
rawFile = File.open(rawFileDir, 'w')
playersRawData.each_with_index { |x, index|
	# make it easy to distinguish between players' raw data
	rawFile << "\# player_#{index}\n" << x << "\n\n\n\n"
}
rawFile.close



# process raw data and create player objects
players = Array.new
playersRawData.each_with_index { |rawData, i|
	# TODO: this looks pretty ugly, consider a .yaml file
	tmpPlayer = Player.new(i)

	if i == 0
		# rank 1 player
		pos = playersRawData[i].index("id=\"") + 4
		tmp = playersRawData[i][pos, playersRawData[i].index("\">", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.id = tmp

		pos = playersRawData[i].index("highest__rank", pos) + 15
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.rank = tmp

		pos = playersRawData[i].index("highest__team", pos) + 15
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.proTeam = tmp

		pos = playersRawData[i].index("highest__level", pos) + 16
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.level = tmp

		pos = playersRawData[i].index("highest__name", pos) + 15
		tmp = playersRawData[i][pos, playersRawData[i].index("</a>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.name = tmp

		pos = playersRawData[i].index("highest__tierrank", pos)
		pos = playersRawData[i].index("<span>", pos) + 6
		tmp = playersRawData[i][pos, playersRawData[i].index("</span>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.tier = tmp

		pos = playersRawData[i].index("<b>", pos) + 3
		tmp = playersRawData[i][pos, playersRawData[i].index("</b>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.lp = tmp[0..-4].sub(',', "")	# remove the LP and the comma

		pos = playersRawData[i].index("text--left", pos) + 12
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.win = tmp

		pos = playersRawData[i].index("text--right", pos) + 13
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.loss = tmp


	elsif i < 5
		# players 2-5
		pos = playersRawData[i].index("id=\"") + 4
		tmp = playersRawData[i][pos, playersRawData[i].index("\">", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.id = tmp

		pos = playersRawData[i].index("highest__rank", pos) + 15
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.rank = tmp

		# if player is not in a team, this is not present
		pos = playersRawData[i].index("highest__team", pos)
		unless pos == nil
			pos += 15
			tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
			unless tmp.index(/\s/) == nil then tmp.strip! end
			tmpPlayer.proTeam = tmp
		else
			pos = 0		# reset pos
		end

		pos = playersRawData[i].index("highest__name", pos) + 15
		tmp = playersRawData[i][pos, playersRawData[i].index("</a>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.name = tmp

		pos = playersRawData[i].index("highest__tierrank", pos)
		pos = playersRawData[i].index("<span>", pos) + 6
		tmp = playersRawData[i][pos, playersRawData[i].index("</span>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.tier = tmp

		pos = playersRawData[i].index("<b>", pos) + 3
		tmp = playersRawData[i][pos, playersRawData[i].index("</b>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.lp = tmp[0..-4].sub(',', "")	# remove the LP and the comma

		pos = playersRawData[i].index("highest__level", pos) + 16
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.level = tmp[3..tmp.length]		# do not include Lv.

		pos = playersRawData[i].index("text--left", pos) + 12
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.win = tmp

		pos = playersRawData[i].index("text--right", pos) + 13
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.loss = tmp

	else
		# rest of the players
		pos = playersRawData[i].index("id=\"") + 4
		tmp = playersRawData[i][pos, playersRawData[i].index("\">", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.id = tmp

		pos = playersRawData[i].index("cell--rank", pos) + 12
		tmp = playersRawData[i][pos, playersRawData[i].index("</td>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.rank = tmp

		pos = playersRawData[i].index("cell--summoner", pos)
		pos = playersRawData[i].index("<span>", pos) + 6
		tmp = playersRawData[i][pos, playersRawData[i].index("</span>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.name = tmp

		pos = playersRawData[i].index("cell--tier", pos) + 12
		tmp = playersRawData[i][pos, playersRawData[i].index("</td>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.tier = tmp

		pos = playersRawData[i].index("cell--lp", pos) + 10
		tmp = playersRawData[i][pos, playersRawData[i].index("</td>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.lp = tmp[0..-4].sub(',', "")	# remove the LP and the comma

		pos = playersRawData[i].index("cell--level", pos) + 13
		tmp = playersRawData[i][pos, playersRawData[i].index("</td>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.level = tmp

		pos = playersRawData[i].index("cell--team", pos) + 12
		tmp = playersRawData[i][pos, playersRawData[i].index("</td>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.proTeam = tmp

		pos = playersRawData[i].index("text--left", pos) + 12
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.win = tmp

		pos = playersRawData[i].index("text--right", pos) + 13
		tmp = playersRawData[i][pos, playersRawData[i].index("</div>", pos) - pos]
		unless tmp.index(/\s/) == nil then tmp.strip! end
		tmpPlayer.loss = tmp
	end

	players.push(tmpPlayer)

}

puts "Processed " + players.size.to_s + " players"



# save processed data to CSV file
csvFileDir = "/home/davide/Desktop/LoLLeaderboardCrawler/csv_" + DateTime.now.strftime('%Q').to_s
csvFile = File.open(csvFileDir, 'w')
csvFile << "#timestamp " << DateTime.now.strftime('%Q').to_s << "\n"
csvFile << "#date " << DateTime.now.to_s << "\n"
csvFile << "#players " << players.size << "\n"
csvFile << "#index,id,rank,name,tier,lp,level,proTeam,win,loss"	<< "\n"	# columns for file
players.each_with_index { |x, index|
	csvFile << index
	csvFile << "," << players[index].id
	csvFile << "," << players[index].rank
	csvFile << "," << players[index].name
	csvFile << "," << players[index].tier
	csvFile << "," << players[index].lp
	csvFile << "," << players[index].level
	csvFile << "," << players[index].proTeam
	csvFile << "," << players[index].win
	csvFile << "," << players[index].loss
	csvFile << "\n"
}
csvFile.close
