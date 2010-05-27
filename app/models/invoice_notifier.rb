class InvoiceNotifier < ActionMailer::Base
  
  self.delivery_method = :activerecord
  self.default_url_options[:host] = "www.jurnalo.com"
  
  def invoice( billing_record )
    user = billing_record.user
    I18n.locale = user.default_locale
    subject       I18n.t( 'email.invoice.subject' )
    from          "Jurnalo User Service <jurnalo.user.service@jurnalo.com>"  
    headers       "return-path" => 'jurnalo.user.service@jurnalo.com'
    recipients    user.email
    sent_on       Time.now
    template      'invoice'
    body          :paid_by_invoice => user.paid_by_invoice, :billing_record => billing_record, 
                  :account_status => billing_record.account_status_points.last
  end

end
