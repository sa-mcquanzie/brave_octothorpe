require "gosu"
include Gosu

#### All non-rendering game logic, i.e anything
#### that should be called from Window.new and Window.update, belongs in this module

module Game
  @@levels = {}  
  @@current_level = 0
  @@lives = 0

  # Accessors for reading / changing the game level
  def self.current_level() @@current_level end
  def self.next_level() @@current_level += 1 end
  def lose_level() @@current_level -= 1 end
  def self.level_change_by(num) @@current_level += num end
  
  ### Grid class, including Tile
  class Grid
    @@tiles = []    
    @@chars = []
    def self.tiles() @@tiles end
    def self.characters() @@chars.sort_by {|char| @@chars.count(char)} end
    def self.subtract_character(char) @@chars.delete_at(@@chars.index(char)) end
    
    # Fill the playing area with tiles containing the letters of the level text
    def self.populate
      @@tiles = []
      pointer = 0
      (0..Settings.window_height).step(Settings.tile_size).each do |y|
        (0..Settings.window_width).step(Settings.tile_size).each do |x|
          newtile = Tile.new(x, y)
          if tile_is_writable?(x,y)
            char = Settings.leveldata[@@current_level][:text][pointer].to_s.downcase
              @@chars << char
              newtile.contents = char
            pointer += 1
          end
          @@tiles << newtile
        end
      end
    end

    # Return the tile object at these co-ordinates
    def self.tile_at(x, y)
      @@tiles.select {|tile| tile.x == x && tile.y == y}.first
    end

    # True if a tile falls within the margins
    def self.tile_is_writable?(x,y)
      y / Settings.tile_size.floor % 3 == 0 &&
      x >= Settings.margin_left &&
      x < Settings.margin_right &&
      y >= Settings.margin_top &&
      y < Settings.margin_bottom
    end

    # Tile type:
    # is_edible - set when a tile contents equals the target letter,
    # is_deadly - set when a tile becomes a solid barrier
    class Tile
      attr_accessor :x, :y, :contents, :is_edible, :is_deadly
      def initialize(x, y)
        @x, @y = x, y
        @contents = :empty
        @is_edible = false
        @is_deadly = false
      end
    end
  end

  # Methods to query & switch between mutually exclusive game states
  class StateMachine
    attr_accessor
    def initialize
      @states = {intro: true, title: false, menu: false, game: false, scores: false}
    end
    def change(state)
      @states.each_pair {|key, val| val = false if key != state}
      @states[state] = true
    end
    def self.current
      @states.invert[true]
    end
  end

  ### Classes for all moving objects, aka the player and tail pieces

  # Moving object superclass
  class Moving
    @@parts = []
    def self.parts() @@parts end
    attr_accessor :x, :y, :direction, :current_tile, :path
    def initialize(x, y, direction)
      @x, @y, @direction = x, y, direction
      @current_tile = Grid.tiles.find {|tile| tile.x == x && tile.y == y}
      @path = [[x, y, @direction]]
      @@parts << self
    end

    def move(direction)
      @direction = direction
      case direction
      when :none then @x, @y = @x, @y
      when :left then @x -= Settings.tile_size * Settings.speed % Settings.window_width - 1 
      when :right then @x += Settings.tile_size * Settings.speed % Settings.window_width - 1 
      when :up then @y -= Settings.tile_size * Settings.speed % Settings.window_height - 1
      when :down then @y += Settings.tile_size * Settings.speed % Settings.window_height - 1
      end
    end

    def self.all_move
      @@parts.each {|part| part.move(part.direction)}      
    end
  end

  # A subclass of Moving which includes animations and has lives
  class Player < Moving
    attr_accessor :lives
    def initialize(x, y, direction)
      super(x, y, direction)
      @animate = Graphics.player_animation
      @lives = 3
    end
  
    def draw
      @animate.start.draw(@x, @y, 4)
    end

    def lives_change_by(num)
      @lives += num
    end
  end

  # A subclass of Moving that takes an image argument,
  # and includes a method to reduce the current tail to one section
  class Tail < Moving
    attr_accessor :image
    def initialize(x, y, direction, image)
      super(x, y, direction)
      @image = image
    end
    def self.clear
      @@parts = @@parts[0..1] if @@parts.size > 2
    end
  end

  # Class for creating a level object from the data in ./assets/levels.yml
  class Level
      attr_accessor :number, :message, :text
      def initialize(number:, message:, text:)
          @number = number
          @message = message
          @text = text
          @@levels[number] = [message, text]
      end
      def self.number(num)
          ObjectSpace.each_object(Level).select {|level| level.number == self.number}
      end
  end

  # Helper methods for setting and getting the position of grid objects
  class Position

    # Set the x/y value of an object to its opposite location if it reaches the edge
    def self.wrap(object)
      object.x = 0 if object.x > (Settings.window_width.floor_to(Settings.tile_size))
      object.x = (Settings.window_width.floor_to(Settings.tile_size)) if object.x < 0
      object.y = 0 if object.y > Settings.window_height.floor_to(Settings.tile_size)
      object.y = (Settings.window_height.floor_to(Settings.tile_size)) if object.y < 0
    end

  # True if an object is within the screen area and correctly aligned to the grid
    def self.within_bounds?(object)
      object.x >= 0 &&
      object.x <= Settings.window_width.floor_to(Settings.tile_size) &&
      object.y >= 0 &&
      object.y <= Settings.window_height.floor_to(Settings.tile_size)
    end

    # True if a collision has occured between a tile and an entity,
    # e.g between a grid position and the player
    def self.collide?(tile, entity)
      tile.is_deadly &&
      tile.contents != :empty &&
      tile.contents != " "
    end
  end
end