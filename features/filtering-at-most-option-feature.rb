When /^I set up the filter to leave most records after filtering$/ do
  @filter_string = "field:seqname:starts_with:chr"
end

When /^set the at_most option to (\d+) lines$/ do |nlines|
  @at_most = nlines.to_i
end

Then /^I should receive a string with (\d+) lines$/ do |nlines|
  @result.lines.count.should == nlines.to_i
end

Then /^the last line should contain "([^"]*)"$/ do |arg|
  @result.lines.map { |x| x }.last.should match(/#{arg}/)
end

