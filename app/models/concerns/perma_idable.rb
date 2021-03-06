module PermaIdable
  extend ActiveSupport::Concern

  included do
    has_many :perma_ids,
             as: :perma_idable,
             dependent: :destroy
  end

  def save_perma_id(args = {})
    text = args[:override_text].present? ?
           args[:override_text] :
           compute_perma_id

    new_perma_id = PermaId.create(
      text: text,
      perma_idable: self
    )

    update_with_new_perma_id if new_perma_id.persisted?

    self
  end

  def take_perma_id(new_perma_id)
    new_perma_id.update_attribute(:perma_idable, self)

    update_with_new_perma_id if new_perma_id.persisted?
  end

  def update_with_new_perma_id
    update_attribute(:perma_id, perma_ids.last.text)
  end

  private

  def compute_perma_id
    # try to use "codes" instead of just "code" in order to make testing
    # easier
    current_code = nil
    if respond_to?(:codes) && codes.present?
      current_code = codes.last.number
    elsif respond_to?(:code) && code.present?
      current_code = code
    end

    PermaIdCreator.new(Hash.new.tap do |hash|
      hash[:name] = name_ka
      hash[:code] = current_code if current_code.present?
    end).compute
  end
end
