module Travis
  module Surveillance
    class Project
      attr_accessor :description, :id, :name, :owner, :slug, :status

      def initialize(name)
        @owner, @name = name.split('/')
        @slug         = name
        populate
      end

      def add_build(json)
        if build = build_for(json['id'])
          return build
        end

        build = Build.new(json.merge({'project' => self}))
        builds << build
        build
      end

      def build_for(id)
        builds.find { |b| b.id == id }
      end

      def building?
        status.nil?
      end

      def builds
        @builds ||= []
      end

      def failed?
        !status.nil? && !passed?
      end

      def passed?
        !status.nil? && status.zero?
      end

      private

      def get_details
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../../spec/support/projects/#{slug.gsub('/', '-')}.json"))
        else
          JSON.parse(open("http://travis-ci.org/#{slug}.json").read)
        end
      end

      def populate
        details = get_details
        @description = details['description']
        @id          = details['id']
        @status      = details['last_build_status']
      end
    end
  end
end
