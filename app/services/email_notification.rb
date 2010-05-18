class EmailNotification < BackgroundService
  
  def start( options = {} )
    send( options[:frequency] )
  end
  
  def finalize( options = {} )
  end
  
  protected
  
  def migrate
    create_email_table unless EnqueuedEmail.table_exists?
  end
  
  def invoice
    PaidByInvoice.each_due do | record |
      record.create_next_billing_record!
    end
  end
  
  def daily
    each_user( daily_value ) do | user |
      alert = user.alert_monitor? ? 'indirect_alert' : 'direct_alert'
      alert_dispatch( alert, user, daily_value, 1.day, :sort_criteria => 0 )
    end
  end
  
  def immediately
    each_user( immediately_value ) do | user |
      alert_dispatch( 'direct_alert', user, immediately_value, 30.minutes, :sort_criteria => 2 )
    end
  end
  
  def weekly
    each_user( weekly_value ) do |user|
      alert = user.alert_monitor? ? 'indirect_alert' : 'direct_alert'
      alert_dispatch( alert, user, weekly_value, 1.week, :sort_criteria => 0 )
    end
  end
  
  def alert_dispatch( alert, user, preference_value, time_interval = 1.hour, options = {} )
    current_time = Time.now
    if user.preference.author_email == preference_value
      cut_off = time_cut_off( user.last_author_email_alert_at, time_interval )
      if cut_off
        stories = author_stories( user, cut_off, current_time, options )
        StoryNotifier.send( "deliver_#{alert}", user, stories, :alert => :author ) if stories.any?
        user.update_attribute( :last_author_email_alert_at, current_time )
      end
    end
    return if parent && parent.respond_to?( :exit? ) && parent.send( :exit? )
    if user.preference.topic_email == preference_value
      cut_off = time_cut_off( user.last_topic_email_alert_at, time_interval )
      if cut_off
        topic_stories( user, cut_off, current_time, options ) do | topic, stories |
          StoryNotifier.send( "deliver_#{alert}", user, stories, :alert => :topic, :topic_id => topic.id, :title => topic.name )
        end
        user.update_attribute( :last_topic_email_alert_at, current_time )
      end
    end
  end
  
  def each_user( preference_value, &block )
    User.with_preference.find_each(
      :conditions => [ 
        'preferences.author_email = :preference_value OR preferences.topic_email = :preference_value', 
        { :preference_value => preference_value } 
      ]) do |user|
      break if parent && parent.respond_to?( :exit? ) && parent.send( :exit? )
      block.call( user )
      break if parent && parent.respond_to?( :exit? ) && parent.send( :exit? )
    end
  end
  
  def daily_value
    @daily_value ||= Preference.select_value_by_name_and_code( :author_email, :daily ).try( :[], :id )
  end
  
  def immediately_value
    @immediately_value ||= Preference.select_value_by_name_and_code( :author_email, :immediately ).try( :[], :id )
  end
  
  def weekly_value
    @weekly_value ||= Preference.select_value_by_name_and_code( :author_email, :weekly ).try( :[], :id )
  end
  
  def author_stories( user, cut_off, current_time, options = {} )
    author_ids = user.author_subscriptions.subscribed.all( :select => 'author_id').collect( &:author_id )
    return [] if author_ids.empty?
    s = StorySearch.new( user, :author, options.merge( :author_ids => author_ids, :custom_time_span => cut_off...current_time, :per_page => 20 ) )
    s.results
  end
  
  def topic_stories( user, cut_off, current_time, options = {}, &block )
    user.topic_subscriptions.email_alert.find_each do |topic|
      stories = topic.stories( options.merge( :per_page => 20, :custom_time_span => cut_off...current_time ) )
      block.call( topic, stories ) if stories.any?
    end
  end
  
  def time_cut_off( last_update_at, time_interval )
    start_time = ( time_interval + 1.hour ).ago
    finish_time = time_interval.ago
    cut_off = ( last_update_at.nil? || start_time > last_update_at ) ? start_time : last_update_at
    cut_off > finish_time ? nil : cut_off
  end
  
  def email_db
    EnqueuedEmail.connection
  end
  
  def create_email_table
    email_db.create_table :enqueued_emails do |t|
      t.column :from, :string
      t.column :to, :string
      t.column :last_send_attempt, :integer, :default => 0
      t.column :mail, :text
      t.column :created_on, :datetime
    end
  end
  
end