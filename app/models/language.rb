class Language < ActiveRecord::Base
  has_many :questionnaires
  has_many :users

  scope :by_locale, lambda {|locale| where(:locale => locale) } rescue nil

  scope :default, where(:locale => 'en') rescue nil

  #  Returns Language id by locale (i.e. locale='en')
  def self.get_id_by_locale(locale)
    result = by_locale(locale.to_s)
    result.empty? ? default.first.id : result.first.id
  end

  def self.default_locale
    self.default.first.locale
  end

  def self.options_for_select
    all.map{|l| [l.language, l.id]} rescue []
  end
end
