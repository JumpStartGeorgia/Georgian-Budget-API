require 'rails_helper'

RSpec.describe User, type: :model do
  let(:super_admin_role) { FactoryGirl.create(:role, name: 'super_admin') }
  let(:site_admin_role) { FactoryGirl.create(:role, name: 'site_admin') }
  let(:content_manager_role) { FactoryGirl.create(:role, name: 'content_manager') }

  let(:new_user) { FactoryGirl.build(:user) }

  it 'is valid with valid attributes' do
    expect(new_user).to be_valid
  end

  describe 'email' do
    it 'is required' do
      new_user.email = ''
      expect(new_user).to have(1).error_on(:email)
    end
  end

  describe 'role' do
    it 'is required' do
      new_user.role = nil
      expect(new_user).to have(1).error_on(:role)
    end
  end

  context 'when is super_admin' do
    let!(:super_admin_user) do
      FactoryGirl.create(:user, role: super_admin_role)
    end

    it 'can manage super_admin user' do
      expect(super_admin_user.can_manage? super_admin_role).to be(true)
    end

    it 'can manage site_admin user' do
      expect(super_admin_user.can_manage? site_admin_role).to be(true)
    end

    it 'can manage content_manager user' do
      expect(super_admin_user.can_manage? content_manager_role).to be(true)
    end
  end

  context 'when is site_admin' do
    let!(:site_admin_user) do
      FactoryGirl.create(:user, role: site_admin_role)
    end

    it 'cannot manage super_admin user' do
      expect(site_admin_user.can_manage? super_admin_role).to be(false)
    end

    it 'can manage site_admin user' do
      expect(site_admin_user.can_manage? site_admin_role).to be(true)
    end

    it 'can manage content_manager user' do
      expect(site_admin_user.can_manage? content_manager_role).to be(true)
    end
  end

  context 'when is content_manager' do
    let!(:content_manager_user) do
      FactoryGirl.create(:user, role: content_manager_role)
    end

    it 'cannot manage super_admin user' do
      expect(content_manager_user.can_manage? super_admin_role).to be(false)
    end

    it 'cannot manage site_admin user' do
      expect(content_manager_user.can_manage? site_admin_role).to be(false)
    end

    it 'cannot manage content_manager user' do
      expect(content_manager_user.can_manage? content_manager_role).to be(false)
    end
  end
end
