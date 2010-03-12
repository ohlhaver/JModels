class StoryNotifier < ActionMailer::Base
  
  self.delivery_method = :activerecord
  self.default_url_options[:host] = "beta.jurnalo.com"
  
  def direct_alert( user, stories, options = {} )
    options.reverse_merge!( :alert => :author )
    I18n.locale = user.default_locale
    subject       I18n.t( "email.#{options[:alert]}.subject", :title => options[:title] )
    from          "Jurnalo.com Email Alert <alerts-noreply@jurnalo.com>"
    headers       "return-path" => 'alerts-noreply@jurnalo.com'
    recipients    user.email
    sent_on       Time.now
    template      'story_alert'
    body          :stories => stories, :alert => options[:alert], :title => options[:title], :user => user, 
                  :all_stories_link => send( "#{options[:alert]}_stories_link", options )
  end
  
  # for daily and weekly alerts for business users 
  def indirect_alert( user, stories, options = {} )
    options.reverse_merge!( :alert => :author )
    I18n.locale = user.default_locale
    subject       I18n.t( "email.#{options[:alert]}.subject", :title => options[:title] )
    from          "Jurnalo.com Email Alert <alerts-noreply@jurnalo.com>"
    headers       "return-path" => 'alerts-noreply@jurnalo.com'
    reply_to      user.email
    recipients    "monitor@jurnalo.com"
    sent_on       Time.now
    template      'story_alert'
    body          :stories => stories, :alert => options[:alert], :title => options[:title], :user => user, 
                  :all_stories_link => send( "#{options[:alert]}_stories_link", options )
  end
  
  protected
  
  def topic_stories_link( options = {} )
    url_for( :controller => 'topics', :action => 'show', :id => options[:topic_id] )
  end
  
  def author_stories_link( options = {} )
    url_for( :controller => 'authors', :action => 'show', :action => 'my' )
  end
  
end