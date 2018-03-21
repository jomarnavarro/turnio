# Loads the configuration from the yaml file.
class Config
    class << self
      ENV_CONFIG_VARIABLES = {
        api_url: 'TURN_API_URL',
        partner_url: 'DASHBOARD_URL',
        browser: 'BROWSER'
      }.freeze
      PROPS_PATH = './features/support/props.yaml'.freeze
      
      def load_config_file
        config = YAML.load_file(PROPS_PATH)
        ENV_CONFIG_VARIABLES.each do |key, variable_name|
          config[key.to_s] = ENV[variable_name] if ENV[variable_name]
        end
        config['browser'] = config['browser'].to_sym
        config['urls']['api'] = config['api_url'] if config['api_url']
        config['urls']['partner_portal'] = config['partner_portal'] if config['partner_portal']
        config
      end
    end
  end
  