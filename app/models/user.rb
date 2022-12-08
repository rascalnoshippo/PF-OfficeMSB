class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable
  validates :login_name, presence: true, uniqueness: true
  validates :password, presence: true, on: :create
	has_one_attached :image

  has_many :messages, dependent: :destroy
  has_many :message_destinations, foreign_key: :receiver_id, dependent: :destroy
  has_many :received_messages, through: :message_destinations, source: :message

  has_many :comments, foreign_key: :commenter_id, dependent: :destroy

  has_many :bulletin_boards, dependent: :destroy
  has_many :bulletin_board_view_flags, dependent: :destroy
  has_many :schedules, dependent: :destroy

  has_many :favorites, dependent: :destroy

  has_many :user_organizations, dependent: :destroy
  has_many :organizations, through: :user_organizations
  has_many :positions, through: :user_organizations

  belongs_to :preferred_org, class_name: "UserOrganization", optional: true

  has_one :config, class_name: "UserConfig", foreign_key: "user_id", dependent: :destroy

  def self.current_user=(user)
    Thread.current[:user] = user # 現在のスレッドにuserを設定するメソッド
  end

  def self.current_user
    Thread.current[:user] # 現在のスレッドに登録されているユーザーを呼び出す
  end

  def icon
    class_name = self == User.current_user ? "text-success" : "text-primary"
    class_name = "text-lightgray" if self.is_invalid
    "<i class='fas fa-user mr-1 #{class_name}'></i>".html_safe
  end

  def get_image
    if is_invalid
      "invalid.jpg"
    elsif image.attached?
      image
    else
      "no_img.jpg"
    end
  end

  def name
    name_org = "#{self[:name]}"
    if self.preferred_org_id
      if self.preferred_org.position_id
        name_org += " #{self.preferred_org.position.name}"
      end
      name_org += "（#{self.preferred_org.organization.name}）"
    end
    name_org += "（無効化されたユーザー）" if self.is_invalid
    return name_org
  end
  
  def name_with_all_org
    # 全所属組織・役職を検索対象に
    name_org = self[:name]
    self.user_organizations.each do |org|
      position = org.position_id ? "・#{org.position.name}" : ""
      name_org += "（#{org.organization.name}#{position}）"
    end
    return name_org
  end

  def update_with_password(params, *options)
    params.delete(:current_password)

    if params[:password].blank?
        params.delete(:password)
        params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end

    result = update(params, *options)

    clean_up_passwords
    result
  end

end
