u = User.new({
  email: 'test@test.com',
  password: 'lkj3lkj3',
  password_confirmation: 'lkj3lkj3',
  name: 'test',
  telegram_channel: 'test',
  gologin_api_token: 'test',
})

u.confirm
u.save!


Schedule.find_each do |s|
  if s.tinder_accounts.present? && s.one_time_tinder_accounts.present?
    s.one_time_tinder_accounts = []
    s.save!
  end
end


u = User.create!(
  name: 'VA1',
  email: 'prince@va.com',
  password: 'Pasdja09djsd0s9j',
  password_confirmation: 'Pasdja09djsd0s9j',
  employer: User.find_by(name: 'Prince'),
)
u.confirm

u = User.create!(
  name: 'Robert2',
  email: 'opulenttinder@protonmail.com',
  password: 'Pasddasliwssl12a!3jss!',
  password_confirmation: 'Pasddasliwssl12a!3jss!',
  gologin_api_token: '',
)
u.confirm


# delete all tinder accounts

u = User.find_by(name: 'Robert2')
accs = u.tinder_accounts
AccountStatusUpdate.where(tinder_account: accs).delete_all
Run.where(tinder_account: accs).delete_all
SwipeJob.where(tinder_account: accs).delete_all
WarmJob.where(tinder_account: accs).delete_all
TinderAccount.where(user: u).delete_all


