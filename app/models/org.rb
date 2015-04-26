class Org < ActiveRecord::Base

  ***REMOVED*** === List of columns ===
  ***REMOVED***   id         : integer 
  ***REMOVED***   name       : string 
  ***REMOVED***   desc       : text 
  ***REMOVED***   created_at : datetime 
  ***REMOVED***   updated_at : datetime 
  ***REMOVED***   abbr       : string 
  ***REMOVED*** =======================

  ***REMOVED*** attr_accessible :desc, :name
  has_many :memberships
  has_many :members, :through => :memberships, :source => :user
  has_many :curations
  has_many :jobs, :through => :curations

  ***REMOVED*** overriden so that org_path uses 
  def to_param
    abbr
  end

  def self.from_param(param)
    find_by_abbr!(param)
  end
end
