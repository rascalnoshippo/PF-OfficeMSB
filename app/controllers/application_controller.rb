class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :user_invalid
  before_action :authenticate_user!
  before_action :set_current_user

  helper_method :date_or_time
  helper_method :pagination_counter

  class Forbidden < ActionController::ActionControllerError
    #403
  end

  def configure_permitted_parameters
		devise_parameter_sanitizer.permit(:sign_up, keys: [:login_name, :email])
  end

 def set_current_user
   User.current_user = current_user
 end

  def date_or_time(time)
    if time.at_beginning_of_day == Time.zone.now.at_beginning_of_day
      time.strftime("%H:%M")
    elsif time.at_beginning_of_year == Time.zone.now.at_beginning_of_year
      time.strftime("%m月%d日(#{I18n.t("date.abbr_day_names")[time.wday]})")
    else
      time.strftime("%Y年%-m月%-d日(#{I18n.t("date.abbr_day_names")[time.wday]})")
    end
  end
  
  def pagination_counter(items)
    #paginationカウンター
    total_count = items.total_count
    per_page = items.limit_value
    current_page = items.current_page
    num_pages = items.total_pages
    count_start = (current_page - 1) * per_page + 1
    count_end = num_pages == 0 ? 0 : (items.last_page? ? total_count : current_page * per_page)
    return "全 #{total_count.to_s(:delimited)} 件中 #{count_start.to_s(:delimited)} - #{count_end.to_s(:delimited)} 件目 ( #{current_page.to_s(:delimited)} / #{num_pages.to_s(:delimited)} ページ)"
  end

  def user_invalid
    user = current_user
    if user_signed_in? && user.is_invalid
      sign_out(user)
    end
  end

  if Rails.env.production? #本番環境のみhttpエラー表示
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    rescue_from ActionController::RoutingError, with: :render_404
    rescue_from Forbidden, with: :render_403
  end

 private

  def render_404
    @header_hidden = true
    render "error/404", status: :not_found
  end

  def render_403
    @header_hidden = true
    render "error/403", status: :forbidden
  end
end
