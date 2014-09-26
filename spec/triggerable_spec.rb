require 'spec_helper'

describe Triggerable do
  before(:each) do
    Engine.clear
    TestTask.destroy_all
  end

  context 'triggers' do
    it 'is' do
      TestTask.trigger on: :after_update, if: {status: {is: 'solved'}} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'is_not' do
      TestTask.trigger on: :after_update, if: {status: {is_not: 'solved'}} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create status: 'solved'
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'completed'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'greater_then' do
      TestTask.trigger on: :after_update, if: {failure_count: {greater_then: 1}} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create failure_count: 0
      expect(TestTask.count).to eq(1)

      task.update_attributes failure_count: 1
      expect(TestTask.count).to eq(1)

      task.update_attributes failure_count: 2
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'less_then' do
      TestTask.trigger on: :after_update, if: {failure_count: {less_then: 2}} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create failure_count: 2
      expect(TestTask.count).to eq(1)

      task.update_attributes failure_count: 1
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'exists' do
      TestTask.trigger on: :after_update, if: {failure_count: {exists: true}} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes failure_count: 1
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'and' do
      TestTask.trigger on: :after_update, if: {and: [{status: {is: 'solved'}}, {kind: {is: 'service'}}]} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved', kind: 'service'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'or' do
      TestTask.trigger on: :after_update, if: {or: [{status: {is: 'solved'}}, {kind: {is: 'service'}}]} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')

      task2 = TestTask.create
      expect(TestTask.count).to eq(3)

      task2.update_attributes kind: 'service'
      expect(TestTask.count).to eq(4)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'in' do
      TestTask.trigger on: :after_update, if: {status: {in: ['solved', 'confirmed']}} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')

      task2 = TestTask.create
      expect(TestTask.count).to eq(3)

      task2.update_attributes status: 'confirmed'
      expect(TestTask.count).to eq(4)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'lambda' do
      TestTask.trigger on: :after_update, if: -> (task) { task.status == 'solved' && task.kind == 'service' } do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved', kind: 'service'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end
  end

  context 'automations' do
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
  end

  context 'short syntax' do
    it 'is' do
      TestTask.trigger on: :after_update, if: {status: 'solved'} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'in' do
      TestTask.trigger on: :after_update, if: {status: ['solved', 'confirmed']} do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')

      task2 = TestTask.create
      expect(TestTask.count).to eq(3)

      task2.update_attributes status: 'confirmed'
      expect(TestTask.count).to eq(4)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'method call' do
      TestTask.trigger on: :after_update, if: :solved? do
        TestTask.create kind: 'follow up'
      end

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end
  end

  context 'actions' do
    class CreateFollowUp < Triggerable::Action
      def run_for! task
        TestTask.create kind: 'follow up'
      end
    end

    it 'custom action' do
      TestTask.trigger on: :after_update, if: {status: 'solved'}, do: :create_follow_up

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(2)
      expect(TestTask.all.last.kind).to eq('follow up')
    end

    it 'custom action chain' do
      TestTask.trigger on: :after_update, if: {status: 'solved'}, do: [:create_follow_up, :create_follow_up]

      task = TestTask.create
      expect(TestTask.count).to eq(1)

      task.update_attributes status: 'solved'
      expect(TestTask.count).to eq(3)
      expect(TestTask.all[-2].kind).to eq('follow up')
      expect(TestTask.all.last.kind).to eq('follow up')
    end
  end
end
