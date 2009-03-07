# When submitting via the web UI, XML content types are wrapped in a
# 'request' element, so that the authenticity_token can be passed along.
# Thus, we need to unwrap the request element if it exists.
ActionController::Base.param_parsers[Mime::XML] = Proc.new do |content|
  parameters = content.blank? ? {} : Hash.from_xml(content)
  parameters.keys == %w(request) ? parameters["request"] : parameters
end
