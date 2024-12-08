require_relative 'complex_type'

module OdataDuty
  module SchemaBuilder
    class EntityType < ComplexType
      attr_reader :property_refs

      def initialize(**kwargs)
        super
        @property_refs = []
      end

      def property_ref(*args)
        property(*args, nullable: false).tap do |property|
          raise 'Multiple Property Reference not yet suported' if property_refs.size.positive?

          property_refs << property
        end
      end

      def prop_ref
        property_refs.first
      end

      class OdataId
        def initialize(id)
          @id = id
        end
      end

      def mapper(val, context)
        context.current['odata_url_base'] ||= context.url_for(url: context.endpoint.url)
        if integer_property_ref?
          int_mapper(val, context)
        else
          string_mapper(val, context)
        end
      end

      def int_mapper(val, context)
        MapperBuilder.build(self, val) do |result, obj|
          result['@odata.id'] = "#{context.current['odata_url_base']}(#{obj.id})"
        end
      end

      def string_mapper(val, context)
        MapperBuilder.build(self, val) do |result, obj|
          result['@odata.id'] = "#{context.current['odata_url_base']}('#{obj.id}')"
        end
      end

      def integer_property_ref?
        @property_ref_raw_type ||= property_refs.first.raw_type
        @property_ref_raw_type == EdmInt64
      end
    end
  end
end
