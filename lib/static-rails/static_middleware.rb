require "rack-proxy"

require_relative "matches_request_to_static_site"

module StaticRails
  class StaticMiddleware
    def initialize(app)
      @matches_request_to_static_site = MatchesRequestToStaticSite.new
      @app = app
      @file_handlers = {}
    end

    def call(env)
      return @app.call(env) unless StaticRails.config.serve_compiled_assets
      req = Rack::Request.new env

      if (req.get? || req.head?) && (site = @matches_request_to_static_site.call(req))
        file_handler = file_handler_for(site)
        path = req.path_info.gsub(/^#{site.url_root_path}/, "").chomp("/")
        if (match = file_handler.match?(path))
          req.path_info = match
          return file_handler.serve(req)
        end
      end

      @app.call(req.env)
    end

    private

    # The same file handler used by Rails when serving up files from /public
    #   See: actionpack/lib/action_dispatch/middleware/static.rb
    def file_handler_for(site)
      @file_handlers[site] ||= ActionDispatch::FileHandler.new(
        StaticRails.config.app.root.join(site.compile_dir).to_s
      )
    end
  end
end