class SourcesRepresenter
  def initialize(sources)
    @sources = sources
  end

  def as_json
    sources.map do |source|
      {
        id: source.id,
        name: source.name,
        access_token: source.access_token,
        account_id: source.account_id,
      }
    end
  end

  private

  attr_reader :sources
end 