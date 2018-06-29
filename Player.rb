class Player

  def initialize(id=-1)
    @objId = id   # useful when using multiple threads
  end

	def initialize(date, id, rank, name, tier, lp, level, proTeam, win, loss)
		# this constructor is better when processing the data from the CSV files
		@id = id
		@date = Array.new
		@rank = Array.new
		@name = Array.new		# I guess a player can change its name
		@tier = Array.new
		@lp = Array.new
		@level = Array.new
		@proTeam = Array.new
		@win = Array.new
		@loss = Array.new

		@date[0], @rank[0], @name[0], @tier[0], @lp[0] = date, rank, name, tier, lp
		@level[0], @proTeam[0], @win[0], @loss[0] = level, proTeam, win, loss
	end

	def pushValues(playerObj)
		if playerObj.is_a?(Player)
			@date.push(playerObj.date.last)
			@rank.push(playerObj.rank.last)
			@name.push(playerObj.name.last)
			@tier.push(playerObj.tier.last)
			@lp.push(playerObj.lp.last)
			@level.push(playerObj.level.last)
			@proTeam.push(playerObj.proTeam.last)
			@win.push(playerObj.win.last)
			@loss.push(playerObj.loss.last)
		end
	end

	attr_accessor :id				# summoner ID (in case name changes), TODO: is constant

	attr_accessor :date			# date when the variables below were collected
	attr_accessor :rank			# rank in the leaderboards
  attr_accessor :name			# name of the player
	attr_accessor :tier			# tier of player
	attr_accessor :lp				# LP
  attr_accessor :level		# level of account
	attr_accessor :proTeam	# name of professional team, if player is part of one
	attr_accessor :win			# number of matches won
	attr_accessor :loss			# number of matches lost

end
