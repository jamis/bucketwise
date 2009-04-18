module OptionHandler
  private

    # For appending info to an XML serialization options hash, where the attributes
    # may be arrays, hashes, or singleton values.
    def append_to_options(options, attribute, extras)
      case options[attribute]
      when Array then
        case extras
        when Array then
          options[attribute].concat(extras)
        when Hash then
          old, options[attribute] = options[attribute], extras
          old.each { |key| options[attribute][key] ||= {} }
        else
          options[attribute] << extras
        end

      when Hash then
        case extras
        when Array then
          extras.each { |key| options[attribute][key] ||= {} }
        when Hash then
          extras.each { |key, value| options[attribute][key] ||= value }
        else
          options[attribute][extras] ||= {}
        end

      else
        options[attribute] = extras
      end
    end
end
