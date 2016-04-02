module TwitterLdsConfFeed
  class Settings
    def self.load
      return @settings if @settings
      settings_yml = Rails.root.join('config', 'settings.yml')
      @settings = YAML.load_file(settings_yml)
    end
  end
end
