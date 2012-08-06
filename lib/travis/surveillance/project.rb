module Travis
  module Surveillance
    class Builds < Array
      def <<(item)
        super

        # A bit expensive, but for now it'll do.
        self.sort_by! { |i| i.id }
        self.slice!(0..-11) if self.size > 10
      end
    end

    class Project
      ATTRIBUTES = [:description, :id, :slug]
      attr_accessor *ATTRIBUTES

      def initialize(slug)
        self.attributes = { 'slug' => slug }
        populate
      end

      def attributes=(attrs = {})
        attrs.each do |key, value|
          send("#{key}=", value) if ATTRIBUTES.include?(key.to_sym)
        end
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
        @builds ||= Builds.new
      end

      def failed?
        !status.nil? && !passed?
      end

      def passed?
        !status.nil? && status.zero?
      end

      def name
        @name ||= @slug.split('/')[1]
      end

      def owner
        @owner ||= @slug.split('/')[0]
      end

      def status
        builds.last.result if builds.any?
      end

      def url
        @url ||= "http://travis-ci.org/#{@slug}"
      end

      private

      def get_details
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../../spec/support/projects/#{slug.gsub('/', '-')}.json"))
        else
          JSON.parse(open("http://travis-ci.org/#{slug}.json").read)
        end
      end

      def get_builds
        if Travis::Surveillance.mocking?
          if File.exists?(File.dirname(__FILE__) + "/../../../spec/support/builds/#{slug.gsub('/', '-')}.json")
            JSON.parse(IO.read(File.dirname(__FILE__) + "/../../../spec/support/builds/#{slug.gsub('/', '-')}.json"))
          else
            []
          end
        else
          JSON.parse(open("http://travis-ci.org/#{slug}/builds.json").read)
        end
      end

      def populate
        self.attributes = details = get_details

        get_builds[0..9].reverse.each do |build_json|
          add_build(build_json)
        end if details['last_build_id']
      end
    end
  end
end
