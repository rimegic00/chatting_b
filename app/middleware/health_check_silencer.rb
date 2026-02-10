class HealthCheckSilencer
  def initialize(app, paths = [])
    @app = app
    @paths = paths
  end

  def call(env)
    if @paths.include?(env["PATH_INFO"])
      Rails.logger.silence do
        @app.call(env)
      end
    else
      @app.call(env)
    end
  end
end
