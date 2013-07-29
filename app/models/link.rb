require 'hipchat-api'

class Link < ActiveRecord::Base
  attr_accessible :date, :from, :link_url, :folder_id, :tag_list
  before_save { |link| link.link_url = link_url.downcase }

  belongs_to :folder

  validates :date, presence: true  
  validates :from, presence: true  
  validates :link_url, presence: true #, uniqueness: { case_sensitive: false }  

  acts_as_taggable
  acts_as_taggable_on :tags

  def self.formatted_posts
    hipchat_api = HipChat::API.new('1fc2ac7967316af15f9d93595ae4e6')

    #room id, YYYY-MM-DD or 'recent' to get last 75 msg, timezone - june
    message_history = hipchat_api.rooms_history(244599, 'recent', 'US/Pacific') 

    all_postings = message_history['messages']
    all_postings.delete_if {|post| post['message'][0] != '_' }

    all_postings.each do |post|
      message = post['message']
      message_array = message.split(" ")
      message_hash = {}
      message_hash['underscore'] = message_array[0][1..-1]
      message_hash['link_url'] = message_array[1]
      message_hash['tags'] = message_array[2..-1]
      post['message'] = message_hash
    end
    return all_postings
  end

  def self.create_links!
    existing_links = Link.all
    formatted_posts.each do |post|
      should_create_link = existing_links.none? {|l| l.link_url == post['message']['link_url'] }
      if should_create_link
        f = Folder.find_by_name(post['message']['underscore'])
        new_link = Link.create
        new_link.date = post['date']
        new_link.from = post['from']['name']
        new_link.link_url = post['message']['link_url']
        new_link.folder_id = f.id  
        new_link.tag_list = post['message']['tags']
        new_link.save
      end 
    end    
  end     
end