#### All graphics logic for the game. Anything that will be called 
#### in the Window.draw loop, to be rendered to the screen, belongs in this module

module Graphics
  def draw_grid
    (0..Settings.window_height).step(Settings.tile_size).each do |y|
      (0..Settings.window_width).step(Settings.tile_size).each do |x|
        Gosu.draw_rect(x, y, Settings.tile_size, Settings.tile_size, 0xff_000000)
      end
    end
  end

  # Render the level text to the screen, colourising the characters based on their status
  def draw_tiles(font)
    Grid.tiles.each do |tile|
      colour = Settings.basic_text_colour
      colour = Settings.highlight_colour if tile.is_edible 
      colour = Settings.enemy_colour if tile.is_deadly
      if tile.is_edible && tile.contents == " "
        font.draw_text("_", tile.x, tile.y, 0, 1, 1, colour) unless tile.contents == :empty
      else
        font.draw_text(tile.contents, tile.x, tile.y, 0, 1, 1, colour) unless tile.contents == :empty
      end      
    end
  end

  def render_tail
    Moving.parts[1..-1]
    .each {|part| part.image
    .draw(part.x.round_to(Settings.tile_size), part.y.round_to(Settings.tile_size), 1, 1, 1, Settings.tail_colour)}
  end

  def display_centered_title(text, font)
    font.draw_text("Collect '#{text}'",
      Settings.window_width / 2 - (text.size * Settings.tile_size) / 2, 0, Settings.tile_size, 1, 1, Settings.title_colour)
  end

  # Positions the happy mailbox or the angry failbox at the bottom left of the screen
  def show_emoticon(var, font)
      var == Settings.mailbox ? z = 0 : z = 3
      font.draw_text(var, Settings.tile_size, Settings.margin_bottom.round_to(Settings.tile_size), z, 1, 1, 0xff_ffff00)
  end

  # Function to overwrite the mailbox / failbox
  def erase_emoticon
      x = Settings.tile_size
      y = Settings.margin_bottom.round_to(Settings.tile_size)
      3.times do |i|
        Gosu.draw_rect(x, y, Settings.tile_size, Settings.tile_size, 0xff_000000, z = 2)
        x += 32
      end
  end

  class Animation
    def initialize(frames, time_in_secs)
      @frames = frames
      @time = time_in_secs * 1000
    end
  
    def start
      @frames[milliseconds / @time % @frames.size]
    end
    def stop
      @frames[0]
    end
  end

  def self.player_animation
    frames = Image.load_tiles(Settings.player_model, Settings.tile_size, Settings.tile_size)
    Animation.new(frames[0..4], 0.2)
  end
end