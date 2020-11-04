module RedmineReporter
  module Liquid
    module Filters
      def sum(input, property=nil)
        return input unless input.is_a?(Array)
        input.inject(0) { |sum, p| sum + property_float_value(p, property) }
      end

      def avg(input, property=nil)
        return input unless input.is_a?(Array)
        return input if input.size.zero?
        input.inject(0) { |sum, p| sum + property_float_value(p, property) / input.size }
      end

      def median(input, property=nil)
        return input unless input.is_a?(Array)
        return input if input.size.zero?
        sorted = float_array_from_values(input, property).sort
        len = input.length
        (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
      end

      def max(input, property=nil)
        return input unless input.is_a?(Array)
        return input if input.size.zero?
        float_array_from_values(input, property).max
      end

      def min(input, property=nil)
        return input unless input.is_a?(Array)
        return input if input.size.zero?
        float_array_from_values(input, property).min
      end

      def duration(distance_in_minutes, options={})
        distance_in_minutes = distance_in_minutes.to_f
        I18n.with_options :locale => options[:locale], :scope => options[:scope] do |locale|
          case distance_in_minutes
            when 0..1
              return distance_in_minutes == 0 ?
                     locale.t("datetime.distance_in_words.less_than_x_minutes", :count => 1) :
                     locale.t("datetime.distance_in_words.x_minutes", :count => distance_in_minutes)

            when 2...45           then locale.t "datetime.distance_in_words.x_minutes",      :count => distance_in_minutes
            when 45...90          then locale.t "datetime.distance_in_words.about_x_hours",  :count => 1
            # 90 mins up to 24 hours
            when 90...1440        then locale.t "datetime.distance_in_words.about_x_hours",  :count => (distance_in_minutes.to_f / 60.0).round
            # 24 hours up to 42 hours
            when 1440...2520      then locale.t "datetime.distance_in_words.x_days",         :count => 1
            # 42 hours up to 30 days
            when 2520...43200     then locale.t "datetime.distance_in_words.x_days",         :count => (distance_in_minutes.to_f / 1440.0).round
            # 30 days up to 60 days
            when 43200...86400    then locale.t "datetime.distance_in_words.about_x_months", :count => (distance_in_minutes.to_f / 43200.0).round
            # 60 days up to 365 days
            when 86400...525600   then locale.t "datetime.distance_in_words.x_months",       :count => (distance_in_minutes.to_f / 43200.0).round
            else
              minutes_with_offset = distance_in_minutes
              remainder                   = (minutes_with_offset % 525600)
              distance_in_years           = (minutes_with_offset.div 525600)
              if remainder < 131400
                locale.t("datetime.distance_in_words.about_x_years",  :count => distance_in_years)
              elsif remainder < 394200
                locale.t("datetime.distance_in_words.over_x_years",   :count => distance_in_years)
              else
                locale.t("datetime.distance_in_words.almost_x_years", :count => distance_in_years + 1)
              end
          end
        end
      end

      # Filter an array of objects
      #
      # input - the object array
      # field - the custom field within each object to filter by
      # value - desired value
      #
      # Returns the filtered array of objects
      def where_custom_field(input, field, value, operator = '==')
        return input unless input.respond_to?(:select)

        input = input.values if input.is_a?(Hash)
        values = value.is_a?(Array) ? value : value.to_s.split(',')

        case operator
        when '=='
          input.select do |object|
            custom_field_value(object, field).to_s == value.to_s.strip
          end
        when '<>'
          input.select do |object|
            custom_field_value(object, field).to_s != value.to_s.strip
          end
        when '>'
          input.select do |object|
            custom_field_value(object, field).to_s > value.to_s
          end
        when '<'
          input.select do |object|
            custom_field_value(object, field).to_s < value.to_s
          end
        when 'match'
          input.select do |object|
            custom_field_value(object, field).to_s.match(value.to_s)
          end
        when 'all'
          input.select do |object|
            (values - multiple_values(object, field)).empty?
          end
        when 'any'
          input.select do |object|
            (values & multiple_values(object, field)).any?
          end
        when 'exclude'
          input.select do |object|
            (values & multiple_values(object, field)).empty?
          end
        else
          []
        end
      end

      # Group an array of items by a custom field value
      #
      # input - the inputted Enumerable
      # field - the custom field
      #
      # Returns an array of Hashes, each looking something like this:
      #  { "name"  => "larry"
      #    "items" => [...] } # all the items where `custom_field_value` == "larry"
      def group_by_custom_field(input, field)
        return input unless groupable?(input)

        groups = input.group_by { |item| custom_field_value(item, field).to_s }
        groups.each_with_object([]) do |(name, items), array|
          array << {
            'name'  => name,
            'items' => items,
            'size'  => items.size
          }
        end
      end

      protected

      def float_array_from_values(items, property)
        items.map { |p| property_float_value(p, property) }
      end

      def property_float_value(element, property)
        if property
          Float(item_property(element, property))
        else
          Float(element)
        end
      end

      def custom_field_value(input, field_name)
        return unless input.respond_to?(:custom_field_values)

        custom_value = input.custom_field_values.detect { |cfv| cfv.custom_field.name == field_name }
        return unless custom_value

        custom_value.custom_field.format.formatted_custom_value(nil, custom_value)
      end

      def multiple_values(input, field_name)
        field_value = custom_field_value(input, field_name)
        field_value.is_a?(Array) ? field_value.map(&:to_s) : [field_value.to_s]
      end
    end

    ::Liquid::Template.register_filter(RedmineReporter::Liquid::Filters)
  end
end
