require 'spec_helper'

describe 'Automations' do
  before(:each) do
    Engine.clear
    TestTask.destroy_all
  end

  it 'after' do
    constantize_time_now Time.utc 2012, 9, 1, 12, 00

    TestTask.automation if: {and: [{updated_at: {after: 24.hours}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 20, 00
    Engine.run_automations(1.hour)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 2, 13, 00
    Engine.run_automations(1.hour)

    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'before' do
    constantize_time_now Time.utc 2012, 9, 1, 12, 00

    TestTask.automation if: {and: [{scheduled_at: {before: 2.hours}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create scheduled_at: Time.utc(2012, 9, 1, 20, 00)
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 15, 00
    Engine.run_automations(1.hour)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 18, 00
    Engine.run_automations(1.hour)
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'after 30 mins with 30 mins interval' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{updated_at: {after: 30.minutes}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 12
    Engine.run_automations(30.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 50
    Engine.run_automations(30.minutes)

    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'before 30 mins with 30 mins interval' do
    constantize_time_now Time.utc 2012, 9, 1, 12, 00

    TestTask.automation if: {and: [{scheduled_at: {before: 30.minutes}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create scheduled_at: Time.utc(2012, 9, 1, 15, 35)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 14, 31
    Engine.run_automations(30.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 15, 03
    Engine.run_automations(30.minutes)
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'after 2 hour with 4 hours interval' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{updated_at: {after: 2.hours}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 00
    Engine.run_automations(4.hours)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 16, 00
    Engine.run_automations(4.hours)

    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'before 4 hour with 2 hour interval' do
    constantize_time_now Time.utc 2012, 9, 1, 12, 00

    TestTask.automation if: {and: [{scheduled_at: {before: 4.hour}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create scheduled_at: Time.utc(2012, 9, 1, 15, 35)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 04, 05
    Engine.run_automations(2.hour)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 10, 01
    Engine.run_automations(2.hour)
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')
  end

  it 'after 2 hour with 15 minutes interval' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{updated_at: {after: 2.hours}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 11, 46
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 13, 46
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 14, 02
    Engine.run_automations(15.minutes)

    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')

    constantize_time_now Time.utc 2012, 9, 1, 14, 17
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)
  end

  it 'before 2 hour with 15 minutes interval' do
    constantize_time_now Time.utc 2012, 9, 1, 12, 00

    TestTask.automation if: {and: [{scheduled_at: {before: 2.hour}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create scheduled_at: Time.utc(2012, 9, 1, 15, 35)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 10, 05
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 13, 30
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')

    constantize_time_now Time.utc 2012, 9, 1, 15, 32
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)
  end

  it 'after greater then 2 hours' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{updated_at: {after: {greater_then: 2.hours}}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 25
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 13, 55
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')

    constantize_time_now Time.utc 2012, 9, 1, 14, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(3)

    constantize_time_now Time.utc 2012, 9, 1, 14, 25
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)
  end

  it 'after less then 2 hours' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{updated_at: {after: {less_then: 2.hours}}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)

    constantize_time_now Time.utc 2012, 9, 1, 12, 25
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(3)

    constantize_time_now Time.utc 2012, 9, 1, 13, 55
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)
    expect(TestTask.all.last.kind).to eq('follow up')

    constantize_time_now Time.utc 2012, 9, 1, 14, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)

    constantize_time_now Time.utc 2012, 9, 1, 14, 25
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)
  end

  it 'before greater then 2 hours' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{scheduled_at: {before: {greater_then: 2.hours}}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create scheduled_at: Time.utc(2012, 9, 1, 20, 00)
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 25
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 17, 55
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 18, 00
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 18, 30
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)
    expect(TestTask.all.last.kind).to eq('follow up')

    constantize_time_now Time.utc 2012, 9, 1, 19, 55
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(3)

    constantize_time_now Time.utc 2012, 9, 1, 20, 00
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)

    constantize_time_now Time.utc 2012, 9, 1, 20, 05
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)

    constantize_time_now Time.utc 2012, 9, 1, 20, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)
  end

  it 'before less then 2 hours' do
    constantize_time_now Time.utc 2012, 9, 1, 11, 55

    TestTask.automation if: {and: [{scheduled_at: {before: {less_then: 2.hours}}}, {status: {is: :solved}}, {kind: {is: :service}}]} do
      TestTask.create kind: 'follow up'
    end

    task = TestTask.create scheduled_at: Time.utc(2012, 9, 1, 20, 00)
    expect(TestTask.count).to eq(1)
    task.update_attributes status: 'solved', kind: 'service'
    expect(TestTask.count).to eq(1)

    constantize_time_now Time.utc 2012, 9, 1, 12, 10
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(2)

    constantize_time_now Time.utc 2012, 9, 1, 12, 25
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(3)

    constantize_time_now Time.utc 2012, 9, 1, 17, 55
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(4)

    constantize_time_now Time.utc 2012, 9, 1, 18, 00
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(5)
    expect(TestTask.all.last.kind).to eq('follow up')

    constantize_time_now Time.utc 2012, 9, 1, 18, 30
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(5)

    constantize_time_now Time.utc 2012, 9, 1, 18, 40
    Engine.run_automations(15.minutes)
    expect(TestTask.count).to eq(5)
  end
end