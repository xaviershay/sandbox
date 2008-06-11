require 'yaml'

ENV["FORMAT"] = "yaml"
results = `ruby #{VIM::evaluate("expand('%:p')")}`
if results =~ /---/
  results.gsub!(/.*---/m, '')

  y = YAML.load('---' + results)
  VIM::command("highlight TestError     guibg=Brown")
  VIM::command("highlight TestException guibg=DarkRed")
  i = nil
  {
    :failures => 'TestError',
    :errors   => 'TestException'
  }.each_pair do |type, matchClass|
    if y[type].empty?
      VIM::command("#{i}match none")
    else
      fail_lines = y[type].collect {|line| "\\%#{line[:line]}l" }.join('\|')
      VIM::command("#{i}match #{matchClass} /#{fail_lines}/")
    end
    i = 2
  end
else
  VIM::command("match none")
  VIM::command("2match none")
end
