require 'odata_duty/edms'

module OdataDuty
  class Property
    attr_reader :name, :nullable

    def initialize(name, type, nullable: true)
      @name = name.to_str.to_sym
      @collection = type.is_a?(Array)
      type = type.first if type.is_a?(Array)
      @type = TYPES_MAPPING[type] || type
      raise "Invalid type #{type.inspect} for #{name}" unless @type

      @nullable = nullable ? true : false
    end

    def raw_type
      return @type unless @type.respond_to?(:__metadata)

      @type.__metadata
    end

    def type
      return raw_type.property_type if raw_type.respond_to?(:property_type)

      raw_type.name
    end

    def collection?
      @collection
    end

    def to_value(value, context)
      raise "#{name} cannot be null" if !nullable && value.nil?

      begin
        result = convert(value, context)
      rescue InvalidValue => e
        raise InvalidValue, "#{name} : #{e.message}"
      end

      raise "#{name} cannot be null" if !nullable && result.nil?

      result
    end

    def convert(value, context)
      return value if value.nil?

      if collection?
        value = value.split(',') if value.is_a?(String)
        value.map { |v| @type.to_value(v, context) }
      else
        @type.to_value(value, context)
      end
    end

    def filter_convert(value, context)
      convert(value, context)
    rescue OdataDuty::InvalidValue
      raise InvalidFilterValue, "Invalid value #{value} for #{name}"
    end

    def to_oas2
      result =
        if raw_type.scalar?
          raw_type.to_oas2(is_collection: collection?)
        else
          collection? ? { 'type' => 'array', 'items' => ref_oas2 } : ref_oas2
        end
      nullable ? result.merge('x-nullable' => true) : result
    end

    private

    def ref_oas2
      { '$ref' => "#/definitions/#{raw_type.name}" }
    end
  end
end
