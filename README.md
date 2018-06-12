# LoLLeaderboardCrawler
## Follow performance of top League of Legends players

This script connects and downloads pages from op.gg, processes them to extract player information and stores in a CSV file. It can download stats from the different regions.

Player information stores includes:
```
attr_accessor :id				# summoner ID (in case name changes)
attr_accessor :rank			# rank in the leaderboards
attr_accessor :name			# name of the player
attr_accessor :tier			# tier of player
attr_accessor :lp				# LP
attr_accessor :level		# level of account
attr_accessor :proTeam	# name of professional team, if player is part of one
attr_accessor :win			# number of matches won
attr_accessor :loss			# number of matches lost
```
