#### All the constant values for the game go here.

module Settings

  # Strings
  def title() "Brave Octothorpe" end
  def mailbox() ":D" end
  def failbox() ">:#" end
  def heart() "<3" end

  # Dimensions
  def window_width() 1280 end
  def window_height() 720 end
  def fullscreen() true end
  def update_interval() 60 end
  def tile_size() 32 end
  def margin_left() 96 end
  def margin_right() 1184 end
  def margin_top() 64 end
  def margin_bottom() 624 end
  def speed() 0.3 end
  def enemy_spawn_rate() 10 / Game.current_level + Game.current_level / 3 end

  # Colours
  def basic_text_colour() Gosu::Color.rgba(255, 255, 255, 180) end
  def highlight_colour() 0xff_00ff00 end
  def tail_colour() 0xff_ff00ff end
  def enemy_colour() 0xff_ff0000 end
  def title_colour() Gosu::Color.rgba(128, 255, 255, 255) end

  # Assets
  def background() "" end #TODO -- perhaps
  def spacer() "../assets/spacer.png" end
  def player_model() "../assets/sprite.png" end
  def leveldata() YAML.load(File.read("../assets/levels.yml")) end
  def font() "../assets/square.ttf" end
  # def intro_text() File.open("./assets/intro.txt") end
end
