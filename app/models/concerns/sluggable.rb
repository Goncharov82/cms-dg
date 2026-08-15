module Sluggable
  extend ActiveSupport::Concern

  CYRILLIC_TRANSLITERATION = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e", "ё" => "yo",
    "ж" => "zh", "з" => "z", "и" => "i", "й" => "y", "к" => "k", "л" => "l", "м" => "m",
    "н" => "n", "о" => "o", "п" => "p", "р" => "r", "с" => "s", "т" => "t", "у" => "u",
    "ф" => "f", "х" => "h", "ц" => "ts", "ч" => "ch", "ш" => "sh", "щ" => "sch",
    "ъ" => "", "ы" => "y", "ь" => "", "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  included do
    before_validation :normalize_slug
    validates :slug, presence: true, uniqueness: true
  end

  private

  def normalize_slug
    source = slug.presence || slug_source
    transliterated = source.to_s.downcase.chars.map { |character| CYRILLIC_TRANSLITERATION.fetch(character, character) }.join
    self.slug = transliterated.parameterize
  end
end
