class StatementsController < ApplicationController
  before_action :find_account, :only => %w(index new create)
  before_action :find_statement, :only => %w(show edit update destroy)

  def index
    @statements = account.statements.balanced
  end

  def new
    @statement = account.statements.build(:ending_balance => account.balance,
      :occurred_on => Date.today)
  end

  def create
    @statement = account.statements.create(statement_params)
    redirect_to(edit_statement_url(@statement))
  end

  def show
  end

  def edit
    @uncleared = account.account_items.uncleared(:with => statement, :include => :event)
  end

  def update
    statement.update(statement_params)
    redirect_to(account)
  end

  def destroy
    statement.destroy
    redirect_to(account)
  end

  protected

  attr_reader :uncleared, :statements
  helper_method :uncleared, :statements

  attr_reader :account, :statement
  helper_method :account, :statement

  def find_account
    @account = Account.find(params[:account_id])
    @subscription = user.subscriptions.find(@account.subscription_id)
  end

  def find_statement
    @statement = Statement.find(params[:id])
    @account = @statement.account
    @subscription = user.subscriptions.find(@account.subscription_id)
  end

  def statement_params
    params.require(:statement)
          .permit(:occurred_on, :ending_balance)
  end
end
