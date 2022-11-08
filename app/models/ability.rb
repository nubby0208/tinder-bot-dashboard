# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    can :access, :rails_admin   # grant access to rails_admin
    can :read, :dashboard       # grant access to the dashboard
    can :read, :dashboard2       # grant access to the dashboard
    can :read, :stats # grant access to the dashboard
    # can :manage, :all

    if user.admin?
      can :manage, :all
    elsif user.employee?
      can [:read, :create, :update], TinderAccount, user: user.employer
      can [:read, :create, :update], FanModel, user: user.employer
      can :read, Location
    else
      can :read, User, employer_id: nil
      can :read, Employee, employer: user
      can [:read, :create, :update, :destroy], Schedule, user: user
      can :read, AccountStatusUpdate, tinder_account_id: user.tinder_accounts.map(&:id)
      can :manage, TinderAccount, user: user
      can :manage, SwipeJob, tinder_account_id: user.tinder_accounts.map(&:id)
      # can :read, SwipeJob, tinder_account_id: user.tinder_accounts.map(&:id)
      # can :create, SwipeJob, tinder_account_id: user.tinder_accounts.map(&:id)
      can :manage, FanModel, user: user
      can [:read, :create], Location
    end
  end
end
