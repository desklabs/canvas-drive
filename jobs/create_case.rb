module CreateCaseJob
  @queue = :standard
  
  def self.perform(params)
    params = params.with_indifferent_access
    customer = find_or_create_customer(params[:email], params[:first_name], params[:last_name])
    ticket   = customer.cases.create({
                 subject: params[:subject],
                 status: 'new',
                 type: 'email',
                 message: {
                   direction: 'in',
                   status: 'received',
                   subject: params[:subject],
                   body: params[:body],
                   from: params[:email],
                   to: mailbox
                 }
               })
    adapter.update_path(ticket.id, params[:file][:id])
  end
  
  def self.find_or_create_customer(email, first_name, last_name)
    puts "#{first_name} #{last_name} <#{email}>"
    begin
      DeskApi.customers.create({
        first_name: first_name,
        last_name: last_name,
        emails: [{ type: 'home', value: email }]
      })
    rescue DeskApi::Error::UnprocessableEntity => err
      return search_for_customer(err, email) if err.errors.to_s.include?('taken')
      raise err
    end
  end
  
  def self.search_for_customer(err, email)
    raise err unless email
    query = DeskApi.customers.search(email: email).per_page(1)
    raise err if query.total_entries == 0
    query.entries.first
  end
  
  def self.adapter
    @adapter ||= ENV['ADAPTER'].classify.constantize.new
  end
  
  def self.mailbox
    @mailbox ||= DeskApi.by_url('/api/v2/mailboxes/inbound').entries.first.email rescue 'noemail@example.com'
  end
end