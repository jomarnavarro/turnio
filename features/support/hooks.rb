 Before do |scenario|
    @scenario = scenario
    @config = Config.load_config_file
    tags = @scenario.source_tag_names.map(&:downcase).map { |x| x.delete('@') }
    @data_row = build_data_row if scenario.outline?
  end
  
After do
  if @scenario.failed?
      tags = @scenario.source_tag_names.map(&:downcase).map { |x| x.delete('@') }
      unless tags.include?('non-gui') || tags.include?('nongui')
        encoded_img = page.driver.browser.screenshot_as(:png)
        embed("data:image/png;base64,#{encoded_img}", 'image/png', '----- SCREENSHOT OF THE FAILURE -----')
      end
    end
    @driver.quit
  end

  def build_data_row
    table = @scenario.all_source.find { |obj| obj.is_a?(Cucumber::Core::Ast::Examples) }
    row = @scenario.all_source.find { |obj| obj.is_a?(Cucumber::Core::Ast::ExamplesTable::Row) }
    table.header.values.zip(row.values).to_h
  end
  
  def step_name
    @step = @scenario.all_source.find { |obj| obj.is_a?(Cucumber::Core::Ast::Step) }
    @step.name
  end
  
  def current_example_row(scenario)
    return unless scenario.outline?
    @current_examples_row = \
      scenario.all_source.find { |obj| obj.is_a?(Cucumber::Core::Ast::ExamplesTable::Row) }.number.to_i
  end
  
  def first_table_line(table)
    fail(TableRequiredError.new('One table row is allowed in step.', step: step_name)) unless table.hashes
    fail(ParameterLinesError.new('One table row is allowed in step.', step: step_name)) \
      unless table.hashes.length == 1
    table.hashes.first
  end
  
  def validate_data_table(table)
    fail(TableRequiredError.new('Table row is allowed in step.', step: step_name)) unless table.hashes
    fail(ParameterLinesError.new('At least one row is required in step.', step: step_name)) \
      unless table.hashes.length >= 1
    table.hashes.first
  end
  
  # This method will bring the table hash row equivalent to the current iteration in the examples
  # table.  It uses - 1 since the examples row starts at one, while the hashes list starts at index 0
  def current_table_line(table)
    fail(TableRequiredError.new('Multiple parameter table rows needed in step.', step: step_name)) \
      unless table.hashes
    unless table.hashes.length > 1
      fail(ParameterLinesError.new('Multiple parameter table rows needed in step.', step: step_name))
    end
    table.hashes[@current_examples_row - 1]
  end
  
  def wait_for_http_response(url)
    time_elapsed = 0
    begin
      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri.request_uri)
      Net::HTTP.new(uri.host, uri.port).start { |http| http.request(req) }
    rescue => ex
      sleep @config['timeouts']['deploy_sleep_time']
      time_elapsed += @config['timeouts']['deploy_sleep_time']
      retry if time_elapsed <= @config['timeouts']['deploy_max_timeout']
      raise(HeimdallError.new('Kueski application is not available'), exception: ex)
    end
  end
  