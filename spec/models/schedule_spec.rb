require 'rails_helper'
include ActiveSupport::Testing::TimeHelpers

# when schedule runs, it will create a job for todays session if possible
# if not possible, it will schedule a job for the next session
# it will not schedule a job beyond the next session
# schedules are run idempotently

RSpec.describe Schedule, type: :model do
  before do
    # set the time to 5:30 EST
    nowtime = Time.zone.now
    t = nowtime.change({ hour: 5, min: 30 })
    Timecop.freeze(t)
  end
  before(:each) { seed }

  it 'only runs active and out_of_likes accounts' do
    s = schedule({ tinder_accounts: [], run_at: nil, run_now: true })
    s.one_time_tinder_accounts = TinderAccount.limit(4)

    expect{s.save!}.to change{SwipeJob.count}.by(3)
    expect{s.run}.to change{SwipeJob.count}.by(0)
    expect{s.run}.to change{SwipeJob.count}.by(0)
    expect{s.run}.to change{SwipeJob.count}.by(0)
    expect{s.run}.to change{SwipeJob.count}.by(0)
    expect(s.one_time_tinder_accounts.count).to be(4)
  end

  it 'works for run once and scheduled on same account' do
    acc = TinderAccount.active.limit(1)
    Timecop.freeze(Time.zone.now.change({ hour: 8, min: 00}))

    s1 = schedule({
      run_now: true,
      run_at: nil,
      tinder_accounts: [],
      one_time_tinder_accounts: acc,
    })
    expect{s1.save!}.to change{SwipeJob.count}.by(1)
    expect{s1.run}.to change{SwipeJob.count}.by(0)
    expect{s1.run}.to change{SwipeJob.count}.by(0)
    expect(SwipeJob.last.status).to eq("pending")

    # reoccurring
    s2 = schedule({
      start_time: '06:00',
      stop_time: '07:00',
      tinder_accounts: acc,
    })
    expect{s2.save!}.to change{SwipeJob.count}.by(1)
    expect{s2.run}.to change{SwipeJob.count}.by(0)
    expect{s2.run}.to change{SwipeJob.count}.by(0)
    expect(SwipeJob.last.status).to eq("scheduled")

    s3 = schedule({
      run_now: true,
      run_at: nil,
      tinder_accounts: [],
      one_time_tinder_accounts: acc,
    })
    expect{s3.save!}.to change{SwipeJob.count}.by(1)
    expect{s3.run}.to change{SwipeJob.count}.by(0)
    expect{s3.run}.to change{SwipeJob.count}.by(0)
    expect(SwipeJob.last.status).to eq("pending")
  end

  context 'when run once' do
    context 'when not run_at' do
      it 'it creates a swipe job' do
        s = schedule({
          run_now: true,
          run_at: nil,
          tinder_accounts: [],
          one_time_tinder_accounts: TinderAccount.active.limit(1)
        })
        expect{s.save!}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect(SwipeJob.last.status).to eq("pending")
      end
    end

    context 'when run_at' do
      it "it doesnt create a swipe job" do
        s = schedule({
          run_at: Time.zone.now,
          tinder_accounts: [],
          one_time_tinder_accounts: TinderAccount.active.limit(1)
        })
        s.save!

        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect(SwipeJob.count).to eq(0)
      end
    end
  end

  context 'when scheduled' do
    context 'scheduled before current time' do
      it 'creates a new job' do
        Timecop.freeze(Time.zone.now.change({ hour: 8, min: 00}))

        s = schedule({
          start_time: '06:00',
          stop_time: '07:00',
          tinder_accounts: TinderAccount.limit(1),
        })

        expect{s.save!}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        run_time = SwipeJob.last.scheduled_at
        expect(run_time).to be < Time.zone.now + s.recurring.hours
        expect(run_time).to be >= s.start_today + s.recurring.hours
        expect(run_time).to be <= s.stop_today + s.recurring.hours
      end
    end

    context 'scheduled after current time' do
      it 'creates a new job' do
        Timecop.freeze(Time.zone.now.change({ hour: 8, min: 0 }))

        s = schedule({
          start_time: '09:00',
          stop_time: '10:00',
          tinder_accounts: TinderAccount.limit(1),
        })

        expect{s.save!}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        run_time = SwipeJob.last.scheduled_at
        # expect(run_time).to be < Time.zone.now
        expect(run_time).to be >= s.start_today
        expect(run_time).to be <= s.stop_today
      end

      it 'creates a new job' do
        Timecop.freeze(Time.zone.now.change({ hour: 8, min: 0 }))

        s = schedule({
          start_time: '09:00',
          stop_time: '10:00',
          tinder_accounts: TinderAccount.limit(1),
        })

        expect{s.save!}.to change{SwipeJob.count}.by(1)

        run_time = SwipeJob.last.scheduled_at
        # expect(run_time).to be < Time.zone.now
        expect(run_time).to be >= s.start_today
        expect(run_time).to be <= s.stop_today
      end
    end

    context 'in time range' do
      it 'it create a new job if necessary' do
        Timecop.freeze(Time.zone.now.change({ hour: 5, min: 30}))
        s = schedule({
          start_time: '04:00',
          stop_time: '06:00',
        })

        expect{s.save!}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)
      end

      it 'it runs a job now' do
        s1 = schedule({
          start_time: '04:00',
          stop_time: '06:00',
        })

        expect{s1.save!}.to change{SwipeJob.count}.by(1)
        run_time = SwipeJob.last.scheduled_at
        expect(run_time.hour).to be >= 4
        expect(run_time.hour).to be <= 6
      end

      it 'keeps on creating jobs' do
        Timecop.freeze(Time.zone.now.change({ hour: 8, min: 00}))
        s1 = schedule({
          start_time: '04:00',
          stop_time: '06:00',
        })
        s1.save!
        s1_start_time = s1.start_today
        s1_stop_time = s1.stop_today
        s1_recurring = s1.recurring

        expect(SwipeJob.count).to eq(1)
        run_time = SwipeJob.last.scheduled_at
        expect(run_time).to be >= s1_start_time + s1_recurring.hours
        expect(run_time).to be <= s1_stop_time + s1_recurring.hours

        # next day 8am
        Timecop.freeze(Time.zone.now + s1_recurring.hours)
        s1.run
        run_time = SwipeJob.last.scheduled_at
        expect(SwipeJob.count).to eq(2)
        updated_recurring = s1_recurring * 2
        expect(run_time).to be >= s1_start_time + updated_recurring.hours
        expect(run_time).to be <= s1_stop_time + updated_recurring.hours

        Timecop.freeze(Time.zone.now + s1_recurring.hours)
        s1.run
        run_time = SwipeJob.last.scheduled_at
        updated_recurring = s1_recurring * 3
        expect(SwipeJob.count).to eq(3)
        expect(run_time).to be >= s1_start_time + updated_recurring.hours
        expect(run_time).to be <= s1_stop_time + updated_recurring.hours
      end
    end

    context 'before todays time range' do
      it 'create a job for today' do
        Timecop.freeze(Time.zone.now.change({ hour: 18, min: 45}))
        s = schedule({ start_time: '19:00', stop_time: '23:00', })

        expect{s.save!}.to change{SwipeJob.count}.by(1)

        Timecop.freeze(Time.zone.now.change({ hour: 19, min: 45}))
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now.change({ hour: 23, min: 45}))
        expect{s.run}.to change{SwipeJob.count}.by(1)

        Timecop.freeze(Time.zone.now + 5.hours)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now.change({ hour: 2, min: 00}))
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now + 1.day) # 2am the next day
        expect{s.run}.to change{SwipeJob.count}.by(1)

        Timecop.freeze(Time.zone.now.change({ hour: 19, min: 45}))
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now.change({ hour: 21, min: 45}))
        expect{s.run}.to change{SwipeJob.count}.by(0)

        expect(SwipeJob.last.scheduled_at).to be <= Time.zone.now.change({ hour: 23, min: 00})

        Timecop.freeze(Time.zone.now.change({ hour: 23, min: 45}))
        expect{s.run}.to change{SwipeJob.count}.by(1)

        expect{s.run}.to change{SwipeJob.count}.by(0)
        SwipeJob.delete_all
        expect{s.run}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        SwipeJob.delete_all
        expect{s.run}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now + 6.hours)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now + 6.hours)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now + 6.hours)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)

        Timecop.freeze(Time.zone.now + 6.hours)
        expect{s.run}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)
      end
    end

    context 'after todays time range' do
      it 'creates job for next sesssion' do
        Timecop.freeze(Time.zone.now.change({ hour: 23, min: 01}))
        s = schedule({ start_time: '19:00', stop_time: '23:00', })

        expect{s.save!}.to change{SwipeJob.count}.by(1)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect{s.run}.to change{SwipeJob.count}.by(0)
        expect(SwipeJob.last.scheduled_at).to be >= Time.zone.now.change({ hour: 19, min: 00}) + s.recurring.hours
        expect(SwipeJob.last.scheduled_at).to be <= Time.zone.now.change({ hour: 23, min: 00}) + s.recurring.hours
      end
    end
  end

  def seed
    user = User.create!(
      email: 'test@test.com',
      password: 'lkj3lkj3',
      password_confirmation: 'lkj3lkj3',
      gologin_api_token: 'lkj3lkj3',
      name: 'test',
    )

    TinderAccount.create!(
      user: user,
      gologin_profile_id: '123412341234123412341234',
      status: 'active',
    )

    TinderAccount.create!(
      user: user,
      gologin_profile_id: 'x23412341234123412341234',
      status: 'active',
    )

    TinderAccount.create!(
      user: user,
      gologin_profile_id: 'z23412341234123412341234',
      status: 'shadowbanned',
    )

    TinderAccount.create!(
      user: user,
      gologin_profile_id: '223412341234123412341234',
      status: 'out_of_likes',
    )
  end

  def schedule(options={})
    default = {
      start_time: "0:00",
      stop_time: "0:00",
      user: User.first!,
      swipes_per_day_min: 200,
      swipes_per_day_max: 210,
      tinder_accounts: TinderAccount.active.limit(1),
    }.merge(options)

    schedule = Schedule.new(default)
  end
end
