require 'action_view'
require 'active_support'
require 'active_support/core_ext/numeric/conversions'
include ActionView::Helpers::DateHelper

class Dashboard2 < RailsAdmin::Config::Actions::Base
  RailsAdmin::Config::Actions.register(self)
  register_instance_option :root? do true end
  register_instance_option :breadcrumb_parent do nil end
  register_instance_option :auditing_versions_limit do 100 end
  register_instance_option :controller do
    proc do
      if true_user != current_user
        stop_impersonating_user
        redirect_to request.referer
      end
    end
  end
  register_instance_option :route_fragment do 'ok' end
  register_instance_option :link_icon do 'fas fa-check' end
  register_instance_option :statistics? do false end
  register_instance_option :history? do true end
end

class Stats < RailsAdmin::Config::Actions::Base
  RailsAdmin::Config::Actions.register(self)
  register_instance_option :root? do true end
  register_instance_option :breadcrumb_parent do nil end
  register_instance_option :auditing_versions_limit do 100 end
  register_instance_option :controller do
    proc do
      if current_user.admin?
        @accounts_counts = TinderAccount.group("created_at::date").order("created_at::date asc").count
        @jobs_count = SwipeJob.count_by_day
        @cumswipes = SwipeJob.cumsum_swipes_by_day(SwipeJob)
        @daily_swipes = SwipeJob.count_swipes_by_day(SwipeJob)
        @daily_jobs = SwipeJob.count_by_day(SwipeJob)

        # stacked jobs
        @jobs_stacked = ((Time.zone.now.to_date-15.days)..(Time.zone.now.to_date)).to_a
        @jobs_stacked_datasets = SwipeJob.datasets
        @jobs_stacked_datasets_checks = SwipeJob.datasets_checks(nil)
      else
        @jobs_count = SwipeJob.count_by_day(SwipeJob.by_user(current_user))
        @accounts_counts = TinderAccount.where(user: current_user).group("created_at::date").order("created_at::date asc").count
        @cumswipes = SwipeJob.cumsum_swipes_by_day(SwipeJob.by_user(current_user))
        @daily_swipes = SwipeJob.count_swipes_by_day(SwipeJob.by_user(current_user))
        @daily_jobs = SwipeJob.count_by_day(SwipeJob.by_user(current_user))

        @jobs_stacked = ((Time.zone.now.to_date-15.days)..(Time.zone.now.to_date)).to_a
        @jobs_stacked_datasets = SwipeJob.datasets(current_user)
        @jobs_stacked_datasets_checks = SwipeJob.datasets_checks(current_user)
      end
      @accounts = TinderAccount.counts_by_date
      @datasets = TinderAccount.datasets
    end
  end
  register_instance_option :route_fragment do 'stats' end
  register_instance_option :link_icon do 'fas fa-chart-bar' end
  register_instance_option :statistics? do false end
  register_instance_option :history? do true end
end

RailsAdmin.config do |config|
  config.asset_source = :sprockets
  config.parent_controller = "::ApplicationController"
  config.default_associated_collection_limit = 1000
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)
  config.authorize_with :cancancan
  config.default_items_per_page = 50
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0
  config.show_gravatar = true

  config.actions do
    dashboard
    dashboard2 do
      visible do
        bindings[:controller]._current_user.admin? || bindings[:controller].true_user != bindings[:controller].current_user
      end
    end
    stats
    index
    new
    export
    bulk_delete do
      only ['Schedule', 'TinderAccount']
    end
    show
    edit
    delete do
      except ['SwipeJob']
    end
    show_in_app
    member :cancel do
      visible do
        bindings[:abstract_model].model.to_s == 'SwipeJob'
      end
      link_icon do
        'fas fa-stop'
      end
      controller do
        Proc.new do
          @object.cancel!
          if @object.errors.present?
            # flash[:error] = "Failed to cancel job #{@object.id}"
            flash[:error] = "Failed to cancel #{@object.errors.full_messages.join(',')}"
          else
            flash[:success] = "Cancelled #{@object.id}"
          end
          # redirect_to back_or_index
          redirect_to request.referer
        end
      end
    end
    member :retry do
      visible do
        bindings[:abstract_model].model.to_s == 'SwipeJob'
      end
      link_icon do
        'fas fa-redo'
      end
      controller do
        Proc.new do
          if @object.retry!
            flash[:success] = "Retrying #{@object.id} #{@object.tinder_account.gologin_profile_name}"
          else
            flash[:error] = "Failed to retry job #{@object.id} #{@object.errors[:retries][0]}"
          end
          redirect_to request.referer
        end
      end
    end
    member :status_check do
      visible do
        bindings[:abstract_model].model.to_s == 'TinderAccount'
      end
      link_icon do
        'fas fa-check'
      end
      controller do
        Proc.new do
          @object.check_status!
          if !@object.errors.present?
            flash[:success] = "Checking status #{@object.id} #{@object.gologin_profile_name}"
          else
            flash[:error] = "Failed to create status_check #{@object.id} #{@object.errors.full_messages.join(",")}"
          end

          redirect_to request.referer
        end
      end
    end
    member :impersonate do
      visible do
        bindings[:abstract_model].model.to_s == 'User' && bindings[:controller]._current_user.admin?
      end
      link_icon do
        'fas fa-user'
      end
      controller do
        Proc.new do
          if _current_user.admin?
            user = User.find(params[:id])
            impersonate_user(user)
          end
          redirect_to dashboard_path
        end
      end
    end
    member :launch_browser do
      visible do
        bindings[:abstract_model].model.to_s == 'TinderAccount' && bindings[:controller]._current_user.admin?
      end
      link_icon do
        'fas fa-desktop'
      end
      controller do
        Proc.new do
          if _current_user.admin?
            # bindings[:object].k8s.create
            stdout = @object.k8s.create
            flash[:success] = "#{stdout} #{@object.id}"
          end
          redirect_to request.referer
        end
      end
    end
    # member :video_link do
    #   visible do
    #     bindings[:abstract_model].model.to_s == 'SwipeJob' &&  ["completed", "failed"].include?(bindings[:object].status) && bindings[:object].id > 1900
    #   end
    #   link_icon do
    #     'fas fa-desktop'
    #   end
    #   controller do
    #     Proc.new do
    #       link = @object.video_link
    #       if @object.errors.present?
    #         flash[:error] = @object.errors[:video_link]
    #         redirect_to request.referer
    #       else
    #         flash[:success] = link
    #         redirect_to link
    #         # redirect_to request.referer
    #       end
    #     end
    #   end
    # end
    # member :image do
    #   visible do
    #     bindings[:abstract_model].model.to_s == 'SwipeJob'
    #   end
    #   link_icon do
    #     'fas fa-image'
    #   end
    # end
    # member :view do
    #   visible do
    #     bindings[:abstract_model].model.to_s == 'SwipeJob' && bindings[:object].port
    #   end
    #   link_icon do
    #     'fas fa-desktop'
    #   end
    #   controller do
    #     Proc.new do
    #       link_to 'Google', 'google.com', :target => '_blank'
    #       # redirect_to "http://100.121.94.78:30000/vnc.html", allow_other_host: true
    #     end
    #   end
    # end
    # member :request_viewer do
    #   visible do
    #     bindings[:controller]._current_user.admin? &&  bindings[:abstract_model].model.to_s == 'TinderAccount'
    #   end
    #   link_icon do
    #     'fas fa-desktop'
    #   end
    #   controller do
    #     Proc.new do
    #       @object.k8s.create_service
    #       flash[:success] = "Assigned view to #{@object.id} #{@object.tinder_account.gologin_profile_name}"
    #       redirect_to back_or_index
    #     end
    #   end
    # end

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.model 'AccountStatusUpdate' do
    parent TinderAccount
    label "Status Update"
    label_plural "Status Updates"
    list do
      field :swipe_job
      # field :tinder_account_id do
      #   label 'Account ID'
      #   formatted_value do
      #     path = bindings[:view].show_path(model_name: 'tinder_account', id: bindings[:object].tinder_account_id)
      #     bindings[:view].link_to(bindings[:object].tinder_account_id, path)
      #   end
      # end
      field :user do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :tinder_account do
        label 'Account'
      end
      field :before_status
      field :status
      field :updated_at do
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
    end
  end

  config.model 'Employee' do
    visible true
    list do
      field :name
      field :email
      field :sign_in_count
      field :failed_attempts
      field :last_sign_in_ip
    end
  end

  config.model 'User' do
    list do
      scopes [:users, :employees]
      field :name
      field :email do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :accounts do
        label 'Accounts'
      end
      field :accounts_last1d do
        label '1d'
      end
      field :accounts_last7d  do
        label '7d'
      end
      field :accounts_last30d  do
        label '30d'
      end
      field :active
      field :banned
      field :captcha
      field :logged_out
      field :proxy_error
      field :shadowbanned
      field :under_review
      field :swipes
      field :jobs
      field :telegram_channel do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :sign_in_count do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :failed_attempts do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
    end

    show do
      field :name
    end
  end


  config.model 'FanModel' do
    label "Model"
    label_plural "Models"
    list do
      field :name
      field :user
      field :accounts
      field :active
      field :banned
      field :captcha
      field :logged_out
      field :proxy_error
      field :shadowbanned
      field :under_review
    end

    edit do
      field :name
      field :user_id, :hidden do
        def value
          bindings[:controller]._current_user.owner_id
        end
      end
    end
  end

  config.model 'Schedule' do
    parent TinderAccount
    list do
      configure :accounts_count
      scopes [:reoccurring, :one_time]
      field :id do
        formatted_value do
          path = bindings[:view].show_path(model_name: 'Schedule', id: bindings[:object].id)
          bindings[:view].link_to(bindings[:object].id, path)
        end
      end
      field :title do
        formatted_value do
          path = bindings[:view].show_path(model_name: 'Schedule', id: bindings[:object].id)
          a = bindings[:view].link_to(bindings[:object].title, path)
          lines = bindings[:object].accounts.pluck(:gologin_profile_name, :status).map {|cols| cols.join(' - ') }.join(" ")
          "<span class='d-inline-block' tabindex='0' data-toggle='tooltip' title='#{lines}'>
          #{a}
          </span>".html_safe
        end
      end
      # field :created_at do
      #   pretty_value do
      #     "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)} ago"
      #   end
      # end
      # field :accounts_count do
      #   label '#Acc'
      #   formatted_value do
      #     lines = bindings[:object].accounts.pluck(:gologin_profile_name, :status).map {|cols| cols.join(' - ') }.join(" ")
      #     "<strong><span style='cursor: pointer;' data-toggle='tooltip' title='#{lines}'>#{value}<span></strong>".html_safe
      #   end
      # end
      field :active_accounts_count do
        label '#Active'
        formatted_value do
          lines = bindings[:object].active_accounts.pluck(:gologin_profile_name).join(" ")
          "<strong><span style='cursor: pointer;' data-toggle='tooltip' title='#{lines}'>#{value}<span></strong>".html_safe
        end
      end
      field :jobs_created_today do
        label 'Jobs1D'
        formatted_value do
          lines = value.pluck(:id).join(" ")
          "<strong><span style='cursor: pointer;' data-toggle='tooltip' title='#{lines}'>#{value.count}<span></strong>".html_safe
        end
      end
      field :user do
        label 'User'
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :job_type
      # field :description
      field :start_time do
        label 'Start'
      end
      field :stop_time do
        label 'Stop'
      end
      field :swipes_per_day_min do
        label 'Min'
      end
      field :swipes_per_day_max do
        label 'Max'
      end
      field :swipes_per_day_increment do
        label 'Incr'
      end
      field :swipes_per_day_increment_max do
        label 'IncrTo'
      end
      # field :split_jobs

      field :recommended_percentage do
        label 'Rec%'
      end
      field :delay do
        label 'Delay (ms)'
      end
      field :recurring do
        label 'Recurring (hrs)'
      end
      field :delay_variance
    end

    show do
      field :swipe_jobs do
        label 'Jobs'
        pretty_value do
          bindings[:view].render({
             partial: 'tinder_accounts/jobs',
             locals: { field: bindings[:object], form: bindings[:form] }
          }).html_safe
        end
      end
      # field :created_at
      field :tinder_accounts do
        label 'Scheduled Accounts'
        visible do
          bindings[:object].tinder_accounts.present?
        end
      end
      field :one_time_tinder_accounts do
        label 'Run Once Accounts'
        visible do
          bindings[:object].one_time_tinder_accounts.present?
        end
      end
      field :active_accounts do
        visible do
          bindings[:object].tinder_accounts.present?
        end
        pretty_value do
          value.map do |v|
            "<li>#{v.title}</li>"
          end.join.html_safe
        end
      end
      # field :description
      field :job_type
      field :recommended_percentage do
        label 'Recommended %'
      end
      field :delay do
        label 'Delay (ms)'
      end
      field :delay_variance
      field :swipes_per_day_min do
        default_value 0
        column_width 100
      end
      field :swipes_per_day_max do
        default_value 0
        column_width 100
      end
      field :swipes_per_day_increment do
        label 'Increment Each Day'
      end
      field :swipes_per_day_increment_max do
        label 'Until It Reaches Max'
      end
      field :start_time do
        label 'Start Executing'
        default_value '1000'
      end
      field :stop_time do
        label 'Stop Executing'
        default_value '1000'
      end
    end

    edit do
      group :one_time do
        active false
        field :one_time_tinder_accounts do
          label 'Tinder Accounts'
          # associated_collection_cache_all false
          associated_collection_scope do
            Proc.new { |scope|
              scope.active
              scope.shadowbanned
            }
          end
        end
        field :run_now do
          label 'Run Now (Ignores times)'
        end
      end
      group :reoccurring do
        active false
        field :tinder_accounts do
          # associated_collection_scope do
          #   Proc.new { |scope| 
          #     scope.active
          #     scope.shadowbanned
          #   }
          # end
        end
        field :swipes_per_day_increment do
          label 'Increment Each Day'
        end
        field :swipes_per_day_increment_max do
          label 'Until It Reaches Max'
        end
        field :recurring do
          label 'Recurring hours'
        end
        # field :description
      end
      group :status_checks do
        active false
        field :status_check_tinder_accounts do
          label 'Tinder Accounts'
          # associated_collection_cache_all false
          associated_collection_scope do
            user_id = bindings[:controller]._current_user.id
            Proc.new { |scope|
              scope.not_deleted.where(user_id: user_id)
            }
          end
        end
      end

      field :job_type
      field :start_time do
        label 'Start Somewhere Between'
        default_value '3600'
      end
      field :stop_time do
        label 'And'
        default_value '3600'
      end
      field :recommended_percentage do
        label 'Recommended %'
      end
      field :delay do
        label 'Delay (ms)'
      end
      field :delay_variance do
        label 'Delay Variance %'
      end
      field :swipes_per_day_min do
        label 'Min Swipes'
        default_value 90
        column_width 100
      end
      field :swipes_per_day_max do
        label 'Max Swipes'
        default_value 120
        column_width 100
      end

      # field :split_jobs
      field :user_id, :hidden do
        def value
          bindings[:controller]._current_user.owner_id
        end
      end
    end
  end

  config.model 'Run' do
    parent TinderAccount
    list do
      scopes [
        # :not_status_check,
        :failed,
        nil,
        :completed,
        :pending,
        :running,
        :past24h,
        # :scheduled,
        # :status_check,
      ]
      field :id
      field :swipe_job
      field :user
      field :tinder_account
      field :swipes
      field :result
      field :created_at do
        label 'Started'
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
      field :failed_at do
        label 'Failed'
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
      field :completed_at do
        label 'Completed'
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
      field :failed_reason do
        formatted_value do
          plines = bindings[:object].failed_reason
          lines =
            if plines
              bindings[:object].failed_reason.gsub(/\n/, "<br/>").html_safe
            else
              nil
            end
          "<span data-bs-html=true class='d-inline-block' tabindex='0' data-toggle='tooltip' title='#{lines}'>
          #{plines ? plines[0..150] : nil}
          </span>".html_safe
        end
      end
    end
    show do
      field :id
      field :swipe_job
      field :swipes
      field :result
      field :created_at do
        label 'Started'
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
      field :failed_at do
        label 'Failed'
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
      field :completed_at do
        label 'Completed'
        pretty_value do
          value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
        end
      end
      field :failed_reason do
        formatted_value do
          bindings[:object].failed_reason.gsub(/\n/, "<br/>").html_safe
        end
      end
    end
  end

  config.model 'Location' do
    object_label_method do
      :custom_label_method
    end
    list do
      sort_by :population
      field :name
      field :population do
        sort_reverse true
        pretty_value do
          ActiveSupport::NumberHelper.number_to_delimited(value)
        end
      end
      # field :created_at do
      #   pretty_value do
      #     value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
      #   end
      # end
      # field :updated_at do
      #   pretty_value do
      #     value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
      #   end
      # end
      # field :user do
      #   label 'Created By'
      #   # visible do
      #   #   bindings[:controller]._current_user.admin?
      #   # end
      # end
    end
    edit do
      field :name
      field :population
      field :user_id, :hidden do
        def value
          bindings[:controller]._current_user.owner_id
        end
      end
    end
  end

  config.model 'TinderAccount' do
    label "Account"
    label_plural "Accounts"
    list do
      sort_by :gologin_profile_name
      scopes [:not_deleted,
        :active,
        :banned,
        :captcha,
        :identity,
        :logged_out,
        :shadowbanned,
        :under_review,
        :profile_deleted,
        :warm_up,
        :gold,
        :no_gold
      ]
      field :id
      field :user do
        label 'Owner'
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      # field :fan_model do
      #   label 'Model'
      # end
      # field :gologin_folder
      field :gologin_profile_name do
        label 'GoLoginName'
        column_width 200
        formatted_value do
          path = bindings[:view].show_path(model_name: 'TinderAccount', id: bindings[:object].id)
          bindings[:view].link_to(bindings[:object].gologin_profile_name, path)
        end
      end
      field :schedule do
        label '📅'
      end
      field :total_swipes do
        label '➡️'
      end
      field :status do
        # pretty_value do
        #   case value
        #   when "active"
        #     "🟢 #{value}"
        #   when "banned"
        #     "🔴 #{value}"
        #   else
        #     "🟡 #{value}"
        #   end
        # end
      end
      field :proxy_active do
        label 'ProxyOK'
      end
      # field :updated_at do
      #   label 'Updated'
      #   pretty_value do
      #     value ? ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone) : nil
      #   end
      # end
      # field :status_checked_at do
      #   label 'Checked'
      #   pretty_value do
      #     value ? ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone) : nil
      #   end
      # end
      field :created_at do
        label 'Created'
        pretty_value do
          value ? ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone) : nil
        end
      end
      field :created_date do
        label '🔥 Created'
        pretty_value do
          value ? ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone) : nil
        end
      end
      field :gold do
        label '🏆'
      end
      field :verified do
        label '✅'
      end
      field :location do
        label '📍'
      end
      field :gologin_profile_id do
        label 'GoLoginID'
        column_width 220
      end
      field :number
      field :email
      field :acc_pass do
        label 'GooglePassword'
        pretty_value do
          bindings[:object].acc_pass
        end
      end
      field :disable_images
      # field :gologin_folder
      field :os do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      # field :user_agent do
      #   column_width 800
      # end
      # field :resolution
      # field :language
      # field :proxy_ip do
      #   visible do
      #     bindings[:controller]._current_user.admin?
      #   end
      # end
      field :proxy_host  do
        column_width 350
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :proxy_country do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :proxy_region do
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      # field :proxy_org

      # field :profile_name
      # field :proxy
      # field :swipes_past24h
      # field :development
      # field :active
    end

    show do
      field :gologin_profile_id
      field :gologin_profile_name
      field :status do
        pretty_value do
          case value
          when "active"
            "🟢 #{value}"
          when "banned"
            "🔴 #{value}"
          else
            "🟡 #{value}"
          end
        end
      end
      field :proxy_active
      field :swipe_jobs do
        label 'Jobs'
        pretty_value do
          bindings[:view].render({
             partial: 'tinder_accounts/jobs',
             locals: { field: bindings[:object], form: bindings[:form] }
          }).html_safe
        end
      end
      field :account_status_updates do
        label 'Status Updates'
        pretty_value do
          bindings[:view].render({
             partial: 'tinder_accounts/status_updates',
             locals: { field: bindings[:object], form: bindings[:form] }
          }).html_safe
        end
      end
      # field :matches do
      #   label 'Matches'
      #   pretty_value do
      #     bindings[:view].render({
      #        partial: 'tinder_accounts/matches',
      #        locals: { field: bindings[:object], form: bindings[:form] }
      #     }).html_safe
      #   end
      # end
      field :schedule
      field :fan_model do
        label 'Model'
      end
      field :acc_pass do
        label 'GooglePassword'
        pretty_value do
          bindings[:object].acc_pass
        end
      end
      field :location
      field :gold
      field :verified
      field :warm_up
      field :disable_images
      # field :proxy_ip
      # field :proxy_country
      # field :proxy_region
      # field :proxy_city
      # field :proxy_hostname
      # field :proxy_org
    end

    edit do
      group :default do
        # field :swipe_jobs do
        #   inline_edit false
        # end
        field :user_id, :hidden do
          def value
            bindings[:controller]._current_user.owner_id
          end
        end
        field :schedule
        field :fan_model
        field :status do
        end
        field :gologin_profile_id do
          label 'GoLogin ID'
          read_only do
            !bindings[:object].new_record?
          end
        end
        field :gologin_profile_name do
          label 'GoLogin Name'
          read_only true
        end
        field :location do
          associated_collection_cache_all false
          # only return locations that are not taken by the user's model
          associated_collection_scope do
            ta = bindings[:object]
            Proc.new { |scope|
              if ta && ta.fan_model.present?
                taken_locations = TinderAccount.where(fan_model: ta.fan_model).pluck(:location_id)
                scope = scope.where.not(id: taken_locations)
              end
            }
          end
        end
        field :number
        field :email
        field :acc_pass do
          label 'GooglePassword'
          pretty_value do
            bindings[:object].acc_pass
          end
        end
        field :created_date do
          label 'Tinder Created Date'
        end
        field :gold
        field :verified
        field :warm_up
        # field :proxy_ip do
        #   read_only true
        # end
        field :disable_images
      end
    end
  end

  config.model 'SwipeJob' do
    label "Job"
    label_plural "Jobs"
    parent TinderAccount

    list do
      scopes [
        nil,
        :my_jobs,
        :scheduled,
        :pending,
        :running,
        :status_check,
        :completed,
        :warm_up,
        :limit_of_likes,
        :gold,
        :no_gold
      ]
      field :id do
        formatted_value do
          path = bindings[:view].show_path(model_name: 'SwipeJob', id: bindings[:object].id)
          bindings[:view].link_to(bindings[:object].id, path)
        end
      end

      # field :video_link do
      #   visible true
      #   label '🎥'
      #   pretty_value do
      #     %{<a target="_blank" href="#{value}">
      #       <i class="fas fa-desktop"></i>
      #     </a>}.html_safe if value
      #   end
      # end
      field :tinder_account do
        column_width 200
        label 'Tinder Name'
      end
      field :job_type do
        label 'Type'
        pretty_value do
          case value
          when "recommended"
            "Rec"
          when "likes"
            "Likes"
          when "status_check"
            '✔️'
          else
            value
          end
        end
      end
      field :schedule do
        label '📅'
      end
      field :status do
        # pretty_value do
        #   case value
        #   when "completed"
        #     "🏁"
        #   when "failed"
        #     "🔴"
        #   when "cancelled"
        #     "🟡"
        #   when "running"
        #     "🏃"
        #   when "scheduled"
        #     "📅"
        #   else
        #     value
        #   end
        # end
      end
      field :account_job_status_result do
        label 'Result'
      end
      # field :tinder_account_status do
      #   label 'Account'
      #   pretty_value do
      #     status = bindings[:object].tinder_account_status
      #     case status
      #     when "captcha_required"
      #       "captcha"
      #     else
      #       status
      #     end
      #   end
      # end
      field :swipes do
        pretty_value do
          perc = ((bindings[:object].swipes * 1.0 / bindings[:object].target) * 100)

          style = case bindings[:object].status
                  when "failed"
                    "bg-danger"
                  when "running"
                    "bg-info"
                  when "pending"
                    "bg-info"
                  when "cancelled"
                    "bg-warning"
                  else
                    perc < 100 ? "bg-warning" : "bg-success"
                    # "bg-success"
                  end

          style = "bg-success" if bindings[:object].job_type == 'limit_of_likes' && bindings[:object].status == 'completed'
          
          %{<div class="progress" style="margin-bottom:0px">
            <div class="#{style} progress-bar animate-width-to" data-animate-length="960" style="width: #{perc}%; overflow: visible; color: black;">
              #{bindings[:object].swipes} / #{bindings[:object].target}
            </div>
          </div>}.html_safe
        end
      end
      field :scheduled_at do
        label '🕑'
        pretty_value do
          %{<div>#{bindings[:object].scheduled_at ? bindings[:object].scheduled_at.in_time_zone.strftime("%B %d, %Y %H:%M") : '' }</div>}.html_safe
        end
        # pretty_value do
        #   value ? value.to_formatted_s(:time) : nil
        #   # if value < Time.zone.now.utc
        #   #   # "#{ActionView::Helpers::DateHelper.distance_of_time_in_words(Time.now.utc, value)} ago"
        #   #   "-"
        #   # else
        #   #   "in #{ActionView::Helpers::DateHelper.distance_of_time_in_words(Time.now.utc, value)}"
        #   # end
        # end
      end
      field :retries do
        label 'Tries'
      end
      # field :runs do
      #   visible do
      #     bindings[:controller]._current_user.admin?
      #   end
      #   pretty_value do
      #     value.count
      #   end
      # end
      # field :created_at do
      #   label 'Created'
      # end
      field :started_at do
        label 'Started'
      end
      field :completed_at do
        label 'Completed'
        pretty_value do
          %{<div>#{bindings[:object].completed_at ? bindings[:object].completed_at.in_time_zone.strftime("%B %d, %Y %H:%M") : '' }</div>}.html_safe
        end
      end
      field :failed_at do
        label 'Failed'
        pretty_value do
          %{<div>#{bindings[:object].failed_at ? bindings[:object].failed_at.in_time_zone.strftime("%B %d, %Y %H:%M") : '' }</div>}.html_safe
        end
        visible do
          bindings[:controller]._current_user.admin?
        end
      end
      field :err_image do
        visible true
        label 'ErrSS'
        pretty_value do
          %{<a target="_blank" href="#{value}">
            <i class="fas fa-image"></i>
          </a>}.html_safe unless value.empty?
        end
      end
      field :recommended_percentage do
        label '->%'
        pretty_value do
          "#{value}%"
        end
      end
      field :delay do
        label 'Delay'
        pretty_value do
          "#{value / 1000.0}s"
        end
      end
      field :delay_variance do
        label 'DelVar'
        pretty_value do
          "#{value}%"
        end
      end
      field :user do
        label 'By'
        pretty_value do
          admin = bindings[:controller]._current_user.admin?
          if admin
            value.name
          else
            value.name == bindings[:controller]._current_user.name ? 'me' : value.name
          end
        end
      end
      field :failed_reason do
        column_width 250
      end
      # field :swiped_at do
      #   label 'Swipe'
      #   pretty_value do
      #     value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
      #   end
      # end
      # field :last_matched_at do
      #   label 'Match'
      #   pretty_value do
      #     value ? "#{ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone)}" : nil
      #   end
      # end
      # field :view_href do
      #   label 'V'
      #   pretty_value do
      #     admin = bindings[:controller]._current_user.admin?
      #     # value = value + "?view_only=true" unless admin
      #     value ? %{<a target="_blank" href="#{value}"><i class="fas fa-eye"></i></a>}.html_safe : nil
      #   end
      # end
      # field :image do
      #   visible true
      #   label 'SS'
      #   pretty_value do
      #     %{<a target="_blank" href="#{value}">
      #       <i class="fas fa-image"></i>
      #     </a>}.html_safe unless value.empty?
      #   end
      # end
    end

    show do
      field :status
      field :tinder_account
      field :job_type
      field :account_job_status_result do
        label 'Result'
      end
      configure :video_links do
      end
      field :video_links do
        formatted_value do
          value.map do |k,v|
            %{<li><a target="_blank" href="#{v}">
              #{k}
            </a></li>}
          end.join(" ").html_safe
        end
      end
      field :created_at do
        label 'Created'
        pretty_value do
          value ? ActionView::Helpers::DateHelper.time_ago_in_words(value.in_time_zone) : nil
        end
      end
      field :err_image do
        visible true
        label 'Error Screenshot'
        # visible do
        #   bindings[:object].status == SwipeJob.statuses['failed']
        # end
        pretty_value do
          bindings[:view].tag(:img, src: bindings[:object].err_image, width: 700, height: 400)
        end
      end
      field :image do
        visible true
        label 'Screenshot'
        # visible do
        #   bindings[:object].status == SwipeJob.statuses['failed']
        # end
        pretty_value do
          bindings[:view].tag(:img, src: bindings[:object].image, width: 700, height: 400)
        end
      end
      field :logs do
        visible true
        pretty_value do
          value.map do |line|
            "<span>#{line}</span><br>"
          end.join('').html_safe
        end
      end
      field :created_by
    end


    edit do
      group :default do
        field :target
        field :user_id, :hidden do
          def value
            bindings[:controller]._current_user.owner_id
          end
        end
        field :tinder_account do
          associated_collection_cache_all false
          associated_collection_scope do
            # job = bindings[:object]
            Proc.new { |scope|
              scope.where.not(gologin_profile_id: nil)
            }
          end
        end
        field :job_type do
          label 'Type'
        end
        field :delay do
          label 'Delay (ms)'
          default_value 1000
        end
        field :delay_variance do
          label 'Delay Variance %'
          default_value 30
        end
        field :recommended_percentage do
          label 'Recommended %'
        end

        field :scheduled_at
      end
    end
  end
end
