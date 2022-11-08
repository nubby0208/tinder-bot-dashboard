# bijan
users = [
  %w(admin bijan.pourriahi+admin@gmail.com lkj3lkj3 admintele xxx),
  %w(Bijan bijan.pourriahi@gmail.com lkj3lkj3 bjtele xxx1),
  %w(Prince thegreatchuk@gmail.com dsad9jas0d9j019jdqsjda prince_telegram eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MjczMzJkMTc5ZTUwYTUyZTIwODI4ODQiLCJ0eXBlIjoiZGV2Iiwiand0aWQiOiI2MzViNDNmYzYyMzI4NjljYjIwNjA0NDcifQ.a5qEZGDbA1pHWgxih1iqM-Z8ea1tDzBiRcEqFbHXLSo),
  %w(Frank frank.steinchen2712@gmail.com xczsda9j091jwdajs xsf eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MTM1MDZkZDUwZGQ2YjU0MzY2MDUxNjQiLCJ0eXBlIjoiZGV2Iiwiand0aWQiOiI2MjdlNzdhMzI3YTk0YjAyYzFmNzRkNzMifQ.q5BFuIaHGZBj-l8kweL1ITV5j2AuwwKgEMKZGYfO9mA),
  %w(Robert robert.oppitz@protonmail.com xcxdasdasdasddwedssd zfs eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MjdlMWZmNTRiODM0NDQzNzMzZDFmZjYiLCJ0eXBlIjoiZGV2Iiwiand0aWQiOiI2MzQ5ZDY3NDEzYWZjOTJhMjI3Mzc3MTAifQ.JSkdeMElwFW2QV6p7K5lyV9IZuCFYc3Vpu5M7fAAeqc),
]

begin
  users.each do |user_args|
    u = User.new({
      email: user_args[1],
      admin: user_args[0] == 'admin',
      password: user_args[2],
      password_confirmation: user_args[2],
      name: user_args[0],
      telegram_channel: user_args[3],
      gologin_api_token: user_args[4],
    })

    u.confirm
    u.save!
  rescue ActiveRecord::RecordNotUnique
    next
  end
end

# frank
# Owner.transaction do
#   frank = User.find_by(name: 'Frank')
#   model = FanModel.find_or_create_by!(user: frank, name: 'model1')
#   TinderAccount.find_or_create_by!(
#     user: frank,
#     gologin_profile_name: "Tinder Leah 12 gold 2.5.",
#     gologin_profile_id: "626e277d80fc497b0de09c80",
#     gologin_folder: '',
#     location: Location.first,
#     fan_model: model,
#     number: '111',
#     email: 'xxx@gmail.com',
#     password: 'xxx',
#     created_date: '2020/01/01',
#     gold: true,
#     verified: true,
#     gologin: true,
#   )

#   TinderAccount.find_or_create_by!(
#     user: frank,
#     gologin_profile_name: "Tinder Lia 15 gold 19:42",
#     gologin_profile_id: "626997666a822bde7903e658",
#     location: Location.second,
#     fan_model: model,
#     number: '111',
#     email: 'xxx@gmail.com',
#     password: 'xxx',
#     created_date: '2020/01/01',
#     gold: true,
#     verified: true,
#     gologin: true,
#   )

#   t = TinderAccount.find_or_create_by!(
#     user: frank,
#     gologin_profile_name: "Tinder Rose 16 gold 3.5.",
#     gologin_profile_id: "626f2b153bca9791175148d4",
#     location: Location.third,
#     fan_model: model,
#     number: '111',
#     email: 'xxx@gmail.com',
#     password: 'xxx',
#     created_date: '2020/01/01',
#     gold: true,
#     verified: true,
#     gologin: true,
#   )

#   SwipeJob.find_or_create_by!(
#     user: frank,
#     tinder_account: t,
#     target: 1,
#   )
# end

# # ROBERT
# Owner.transaction do
#   robert = User.find_by(name: 'Robert')
#   t = TinderAccount.find_or_create_by!(
#     user: robert,
#     gologin_profile_name: "Lana Roze",
#     gologin_profile_id: '6265f2c3f470fe640423514c',
#     active: true,
#   )
#
#   SwipeJob.find_or_create_by!(
#     user: robert,
#     tinder_account: t,
#     target: 1,
#   )
# end
#
# # Prince
# Owner.transaction do
#   prince = User.find_by(name: 'Prince')
#   tinder_account = TinderAccount.find_or_create_by!(
#     user: prince,
#     gologin_profile_name: "Ashley 39",
#     gologin_profile_id: "626b328aa7a1b4af904db61e",
#     active: true,
#   )
#
#   tinder_account2 = TinderAccount.find_or_create_by!(
#     user: prince,
#     gologin_profile_name: "Ashley Tinder 17 R",
#     gologin_profile_id: "625dfee7fb2d0485b68dba8a",
#     active: true,
#   )
# end
#
#
