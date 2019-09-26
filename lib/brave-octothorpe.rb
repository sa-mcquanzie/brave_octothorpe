require_relative "./brave-octothorpe/game"
require_relative "./brave-octothorpe/graphics"
require_relative "./brave-octothorpe/settings"

require "gosu"
require "rounding"
require "yaml"

include Game, Gosu, Graphics, Settings

class BraveOctothorpe < Window
  def initialize
    super Settings.window_width, Settings.window_height, Settings.fullscreen
    self.update_interval = Settings.update_interval
    self.caption = Settings.title
    @font = Font.new(self, Settings.font, Settings.tile_size)
    @small_font = Font.new(self, Settings.font, Settings.tile_size / 2)
    @player = Player.new(0, 0, :none)
    new_level
  end

  # Set the variables for the next level, clear the tail array and repopulate the grid
  def new_level
    @level = Level.new(Settings.leveldata[Game.next_level])
    @message = @level.message.downcase.split("")
    @target, @completed = @message, ""
    Tail.clear
    @head = Tail.new(@player.x, @player.y, :none, Image.new(Settings.spacer))    
    Grid.populate
    @player.x, @player.y = 0, 0
    @active_tile = Grid.tile_at(0, 0)
    @mailbox = ""
    @enemy_timer = Time.new
  end

  # Main game loop. Runs as many times per second as defined in Settings.update_interval
  def update

    # Check if the player is colliding with a deadly tile. If so: Lose!
    if Position.collide?(@active_tile, @player)
      timer = Time.new
      until Time.now - timer > 3
        @player.move(:none)
      end
      Game.lose_level
      new_level
    end

    # Periodically activate a deadly tile in order of decreasing rarity
    if @player.direction != :none
      if Time.now - @enemy_timer > Settings.enemy_spawn_rate
        eligable_tiles = []
        Grid.tiles.each do |tile|
          if !@target.include?(tile.contents) &&
          tile.is_deadly == false &&
          tile.contents != :empty &&
          tile.contents != " "
            eligable_tiles << tile.contents
          end
        end
        @enemy_tile = Grid.characters.detect{|tile| eligable_tiles.include? (tile)}
        Grid.tiles.each do |tile|
          tile.is_deadly = true if tile.contents == @enemy_tile
        end
        @enemy_timer = Time.new
      end
    end

    # Align the player's position to the closest tile on the grid
    if Position.within_bounds?(@player)
      @player.x, @player.y = @player.x.round_to(Settings.tile_size), @player.y.round_to(Settings.tile_size)
    end

    # Wrap the player around the screen if they reach the edge
    Position.wrap(@player)

    # Respond to Keypresses
    if button_down? KbEscape
      close
      puts "You reached level #{Game.current_level}. Goodbye!"
      exit
    end
    Moving.parts.each {|part| part.move :none if button_down? KbSpace}
    @player.move(:left) if button_down?(KbLeft) && Position.within_bounds?(@player) && (@player.direction != :right)
    @player.move(:right) if button_down?(KbRight) && Position.within_bounds?(@player) && (@player.direction != :left)
    @player.move(:up) if button_down?(KbUp) && Position.within_bounds?(@player) && (@player.direction != :down)
    @player.move(:down) if button_down?(KbDown) && Position.within_bounds?(@player) && (@player.direction != :up)

    # Move all the movable objects in the game
    @player.move(@player.direction)
    Moving.all_move
    
    # Update the player's location on the grid
    if Position.within_bounds?(@player)
      @active_tile = Grid.tiles
      .find {|tile| tile.x == @player.x
      .round_to(Settings.tile_size) && tile.y == @player.y
      .round_to(Settings.tile_size)}
    end

    # Have the invisible spacer tile track the player's position
    @head.x, @head.y, @head.direction = @player.path.last[0], @player.path.last[1], @player.path.last[2]  
      
    # Update all the tail sections so the previous location of the section in front
    # becomes their current location
    Moving.parts.each_with_index do |section, index|
      section.path << [section.x.round_to(Settings.tile_size), section.y.round_to(Settings.tile_size), section.direction]
      leader = Moving.parts[index-1].path.last if index > 0
      section.x, section.y, section.direction = leader[0], leader[1], leader[2] if index > 0
      section.path.drop(1) if section.path.size > @message.size + 1
    end
    
    # If the player moves over a target tile create a new tail section
    if @active_tile.is_edible
      lastpath = Moving.parts.last.path.last
      image = Image.from_text(@active_tile.contents, Settings.tile_size, options={font: Settings.font, bold: true})
      Tail.new(lastpath[0], lastpath[1], lastpath[2], image)
      @completed << @active_tile.contents.to_s
      Grid.subtract_character(@active_tile.contents)
      @active_tile.contents = :empty
      @target = @target.drop(1)
      Grid.tiles.each {|tile| tile.is_edible = false}
    end

    # Set the target letter
    Grid.tiles.each {|tile| tile.is_edible = true if tile.contents == @target[0]}

    # Check if the player has collected all the target letters and in the case that
    # they have, check if they have arrived at the mailbox. If so: Level up!
    if @message.join("") == @completed
      if @active_tile.y == Settings.margin_bottom.round_to(Settings.tile_size) &&
        @active_tile.x.between?(Settings.tile_size, Settings.tile_size * 2)
        @player.move(:none)
        sleep 2
        new_level
      end
    end
  end

  # Loop to render elements to the screen
  def draw
    @player.draw
    Graphics.render_tail
    Graphics.draw_tiles(@font)
    Graphics.display_centered_title(@message.join(""), @small_font)
    Graphics.show_emoticon(Settings.mailbox, @font) if @message.join("") == @completed    
    if Position.collide?(@active_tile, @player)
      Graphics.erase_emoticon
      Graphics.show_emoticon(Settings.failbox, @font) 
    end
  end
end